defmodule Solitaire.Game do
  @type t :: %__MODULE__{}

  @black_suits ~w(spade club)
  @red_suits ~w(diamond heart)
  @suits ~w(spade diamond heart club)
  @ranks ~w(A 2 3 4 5 6 7 8 9 10 J D K)
  @deck Enum.flat_map(@ranks, fn r -> Enum.map(@suits, fn s -> {s, r} end) end)

  defstruct cols: [],
            deck: @deck,
            deck_length: 8,
            foundation: %{"spade" => nil, "diamond" => nil, "heart" => nil, "club" => nil}

  def perform_autowin(
        %{
          foundation: %{"club" => "K", "diamond" => "K", "heart" => "K", "spade" => "K"}
        } = game
      ),
      do: game

  def perform_autowin(%{cols: cols} = game) do
    cols
    |> Enum.with_index()
    |> Enum.reduce(game, fn {col, index}, game ->
      game = move_to_foundation(game, index)
      Phoenix.PubSub.broadcast(Solitaire.PubSub, "game", {:tick, game})
      :timer.sleep(50)
      game
    end)
    |> perform_autowin()
  end

  def move_to_foundation(%{deck: deck, foundation: foundation} = game, :deck) do
    {from_suit, from_rank} = current(deck) |> IO.inspect(label: "current")

    foundation_card = Map.fetch!(foundation, from_suit)

    cond do
      foundation_card == nil && from_rank == "A" ->
        move_from_deck_to_foundation(game, from_suit, from_rank)

      rank_index(from_rank) - 1 ==
          rank_index(foundation_card) ->
        IO.inspect("CAN PUT TO FOUNDATION")

        move_from_deck_to_foundation(game, from_suit, from_rank)

      true ->
        game
    end
  end

  def move_to_foundation(%{cols: cols, foundation: foundation} = game, from_col_num) do
    from_column = %{cards: cards} = Enum.at(cols, from_col_num)

    card = List.first(cards)

    if card do
      {from_suit, from_rank} = card
      foundation_card = Map.fetch!(foundation, from_suit)

      cond do
        foundation_card == nil && from_rank == "A" ->
          move_from_deck_to_foundation(game, from_suit, from_rank, from_column, from_col_num)

        rank_index(from_rank) - 1 ==
            rank_index(foundation_card) ->
          move_from_deck_to_foundation(game, from_suit, from_rank, from_column, from_col_num)

        true ->
          game
      end
    else
      game
    end
  end

  defp move_from_deck_to_foundation(%{foundation: foundation, deck: deck} = game, suit, rank) do
    game
    |> Map.put(:foundation, %{foundation | suit => rank})
    |> Map.put(:deck, rest_deck(deck))
  end

  defp move_from_deck_to_foundation(
         %{foundation: foundation, cols: cols} = game,
         suit,
         rank,
         from_column,
         from_col_num
       ) do
    from_column = take_card_from_column(from_column)

    new_cols = List.replace_at(cols, from_col_num, from_column)

    game
    |> Map.put(:foundation, %{foundation | suit => rank})
    |> Map.put(:cols, new_cols)
  end

  @doc "Возвращает перемешанную колоду карт"
  @spec shuffle :: Solitaire.Game.t()
  def shuffle() do
    %{%__MODULE__{} | deck: Enum.shuffle(@deck)}
  end

  @doc """
    Возвращает tuple, первый элемент которого - полученные `count` карт из колоды,
    второй - оставшаяся колода
  """
  @spec take_card_from_deck(list(tuple), integer) :: {[tuple], [tuple]}
  def take_card_from_deck(deck, count) do
    Enum.split(deck, count)
  end

  @doc """
    Берет следующую карту из колоды
  """
  def change(%{deck: [h | [[] | t]]}) do
    new_deck = (t ++ [h]) |> List.flatten() |> split_deck_by(3)
    new_deck ++ [[]]
  end

  def change(%{deck: [h | rest]}) do
    rest ++ [h]
  end

  @doc """
    Разбивает колоду на массив из `count` карт
  """
  @spec split_deck_by(list(tuple), pos_integer) :: [[any]]
  def split_deck_by(deck, count) do
    Enum.chunk_every(deck, count)
  end

  @spec move_from_column(%{cols: any}, integer, integer) ::
          {:error, %{cols: any}} | {:ok, %{cols: [any]}}
  def move_from_column(%{cols: cols} = game, from_col_num, to_col_num) do
    from_column = %{cards: from_cards, unplayed: unplayed} = Enum.at(cols, from_col_num)
    to_column = Enum.at(cols, to_col_num)

    if length(from_cards) == unplayed + 1 do
      move_one_card_from_column(game, from_column, to_column, from_col_num, to_col_num)
    else
      move_cards_from_column(game, from_column, to_column, from_col_num, to_col_num)
    end
  end

  defp move_cards_from_column(
         %{cols: cols} = game,
         from_column,
         to_column,
         from_col_num,
         to_col_num
       ) do
    %{cards: from_cards, unplayed: unplayed} = from_column
    %{cards: to_cards} = to_column

    to = List.first(to_cards) |> IO.inspect(label: "to")

    for_move_count = (length(from_cards) - unplayed) |> IO.inspect(label: "from count")

    {cards_to_move, rest_cards} = Enum.split(from_cards, for_move_count)

    if can_move?(to, List.last(cards_to_move)) |> IO.inspect(label: "can move!!!") do
      from_column = %{
        cards: rest_cards,
        unplayed: maybe_decrease_unplayed(length(rest_cards), unplayed)
      }

      to_column = %{to_column | cards: cards_to_move ++ to_cards}

      new_cols =
        List.replace_at(cols, from_col_num, from_column) |> List.replace_at(to_col_num, to_column)

      {:ok, %{game | cols: new_cols}}
    else
      {:error, game}
    end
  end

  defp move_one_card_from_column(
         %{cols: cols} = game,
         from_column,
         to_column,
         from_col_num,
         to_col_num
       ) do
    %{cards: [from | _]} = from_column
    %{cards: to_cards} = to_column
    to = List.first(to_cards) |> IO.inspect(label: "to")

    if can_move?(to, from) |> IO.inspect(label: "CAN MOVE") do
      from_column = take_card_from_column(from_column)
      to_column = %{to_column | cards: [from | to_cards]}

      new_cols =
        List.replace_at(cols, from_col_num, from_column) |> List.replace_at(to_col_num, to_column)

      {:ok, %{game | cols: new_cols}}
    else
      {:error, game}
    end
  end

  defp take_card_from_column(%{cards: [_ | rest_cards], unplayed: unplayed}) do
    %{cards: rest_cards, unplayed: maybe_decrease_unplayed(length(rest_cards), unplayed)}
  end

  defp maybe_decrease_unplayed(_, 0), do: 0

  defp maybe_decrease_unplayed(length_of_cards_rest, unplayed)
       when length_of_cards_rest > unplayed,
       do: unplayed

  defp maybe_decrease_unplayed(_, unplayed), do: unplayed - 1

  defp rest_deck([[_h | t] | [[] | rest]]) do
    [t | rest] ++ [[]]
  end

  defp rest_deck([[_current | []] | rest_deck]) do
    rest_deck
  end

  defp rest_deck([[_current | rest] | rest_deck]) do
    [rest | rest_deck]
  end

  defp current(deck) do
    deck |> List.first() |> List.first()
  end

  @spec move_from_deck(%{cols: any, deck: [...]}, integer) :: %{cols: any, deck: [...]}
  def move_from_deck(
        %{deck: deck, cols: cols} = game,
        column
      ) do
    if deck_non_empty?(deck) do
      current = current(deck)

      deck = rest_deck(deck)

      col = %{cards: cards} = Enum.at(cols, column)

      upper_card = List.first(cards)

      if can_move?(upper_card, current) do
        cards = [current | cards]

        cols = List.replace_at(cols, column, %{col | cards: cards})

        game
        |> Map.put(:cols, cols)
        |> Map.put(:deck, deck)
      end
    else
      game
    end
  end

  def cols_empty?(%{cols: cols}), do: cols_empty?(cols)

  def cols_empty?(cols) do
    unplayed = cols |> Enum.map(& &1.unplayed) |> Enum.uniq() == [0]
  end

  def deck_empty?(%{deck: deck}), do: deck_empty?(deck)

  def deck_empty?(deck), do: !deck_non_empty?(deck)

  defp deck_non_empty?(deck) do
    deck |> List.flatten() != []
  end

  defp can_move?(nil, {_, "K"}), do: true

  defp can_move?(nil, _), do: false

  defp can_move?(_, nil), do: false

  defp can_move?({suit, _}, {suit, _}), do: false

  defp can_move?({_, rank}, {_, rank}), do: false

  # to, from
  defp can_move?({col_suit, col_rank}, {deck_suit, dec_rank}) do
    with 1 <- rank_index(col_rank) - rank_index(dec_rank),
         true <- suits_of_different_color?(deck_suit, col_suit) do
      true
    else
      _ -> false
    end
  end

  defp rank_index(rank), do: Enum.find_index(@ranks, &(&1 == rank))

  defp suits_of_different_color?(suit, suit), do: false

  defp suits_of_different_color?(suit1, suit2) do
    if suit1 in @black_suits do
      suit2 in @red_suits
    else
      suit2 in @black_suits
    end
  end
end
