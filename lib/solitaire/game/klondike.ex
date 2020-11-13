defmodule Solitaire.Game.Klondike do
  alias Solitaire.Games
  alias Solitaire.Game.Klondike.Foundation

  @behaviour Solitaire.Games

  @black_suits ~w(spade club)a
  @red_suits ~w(diamond heart)a

  @deck Enum.flat_map(Games.ranks(), fn r -> Enum.map(Games.suits(), fn s -> {s, r} end) end)

  @impl Solitaire.Games
  def load_game(_params) do
    game =
      %{deck: rest_deck} =
      Enum.reduce(0..6, shuffle(), fn i, game -> Games.take_cards_to_col(game, i, i + 1, i) end)

    Map.put(game, :deck, [[] | Games.split_deck_by(rest_deck, 3)])
  end

  @impl Games
  def move_to_foundation(%{deck: deck, foundation: foundation} = game, :deck, opts \\ []) do
    # auto = Keyword.get(opts, :auto, false)

    if current = current(deck) do
      {from_suit, from_rank} = current
      foundation_rank = Foundation.fetch_rank_from_foundation(foundation, from_suit)

      if (foundation_rank == nil && from_rank == List.first(Games.ranks())) ||
           (Games.rank_index(from_rank) - 1 ==
              Games.rank_index(foundation_rank) &&
              Foundation.can_automove?(
                foundation,
                foundation_rank,
                from_suit,
                Keyword.get(opts, :auto, false)
              )) do
        move_from_deck_to_foundation(game, from_suit, ["deck"])
      else
        game
      end
    else
      game
    end
  end

  @impl Games
  def move_to_foundation(%{cols: cols, foundation: foundation} = game, from_col_num, opts) do
    auto = Keyword.get(opts, :auto, false)

    %{cards: cards} = Enum.at(cols, from_col_num)

    if card = List.first(cards) do
      {from_suit, from_rank} = card
      foundation_rank = Foundation.fetch_rank_from_foundation(foundation, from_suit)

      if (foundation_rank == nil && from_rank == List.first(Games.ranks())) ||
           (Games.rank_index(from_rank) - 1 ==
              Games.rank_index(foundation_rank) &&
              Foundation.can_automove?(foundation, foundation_rank, from_suit, auto)) do
        Games.move_from_column_to_foundation(
          game,
          from_suit,
          from_col_num,
          1,
          ["column", from_col_num],
          Foundation
        )
      else
        game
      end
    else
      game
    end
  end

  defp move_from_deck_to_foundation(%{foundation: foundation, deck: deck} = game, suit, from) do
    game
    |> Map.put(:foundation, Foundation.push(foundation, suit, from))
    |> Map.put(:deck, deck |> rest_deck |> split_deck_if_reached_the_end())
  end

  @doc "Возвращает перемешанную колоду карт"
  @spec shuffle :: Solitaire.Games.t()
  def shuffle() do
    %{%Games{} | deck: Enum.shuffle(@deck)}
  end

  @doc """
    Берет следующую карту из колоды
  """
  @spec change(Game.t()) :: [tuple]

  def change(%{deck: [h | [[] | _] = rest]}) do
    split_deck_if_reached_the_end(rest ++ [h])
  end

  def change(%{deck: [[] | _rest] = deck}) do
    split_deck_if_reached_the_end(deck)
  end

  def change(%{deck: [h | rest]}) do
    rest ++ [h]
  end

  defp split_deck_if_reached_the_end([[] | rest]) do
    (rest |> List.flatten() |> Games.split_deck_by(3)) ++ [[]]
  end

  defp split_deck_if_reached_the_end(deck), do: deck

  def move_from_foundation(game, suit, to_col_num) when is_binary(suit),
    do: move_from_foundation(game, String.to_existing_atom(suit), to_col_num)

  def move_from_foundation(
        %{cols: cols, foundation: foundation} = game,
        suit,
        to_col_num
      ) do
    from_rank = Foundation.fetch_rank_from_foundation(foundation, suit)

    to_column = %{cards: [to | _] = cards} = Enum.at(cols, to_col_num)

    if from_rank && can_move?(to, {suit, from_rank}) do
      game
      |> Map.put(:foundation, Foundation.pop(foundation, suit))
      |> Games.update_cols(to_col_num, %{to_column | cards: [{suit, from_rank} | cards]})
    else
      game
    end
  end

  @impl Games
  @spec move_from_column(%{cols: any}, integer, integer) ::
          {:error, Games.t()} | {:ok, Games.t()}
  def move_from_column(game, from_col_num, to_col_num) do
    Games.move_cards_from_column(game, from_col_num, to_col_num, &can_move?(&1, &2))
  end

  defp rest_deck([[], [_h | t] | rest]) do
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

  @impl Games
  @spec move_from_deck(%{cols: any, deck: [...]}, integer) ::
          {:ok, Games.t()} | {:error, Games.t()}
  def move_from_deck(
        %{deck: deck, cols: cols} = game,
        column
      ) do
    if deck_non_empty?(deck) do
      current = current(deck)

      deck = deck |> rest_deck() |> split_deck_if_reached_the_end()

      col = %{cards: cards} = Enum.at(cols, column)
      upper_card = List.first(cards)

      if can_move?(upper_card, current) do
        cards = [current | cards]

        {:ok,
         game
         |> Games.update_cols(column, %{col | cards: cards})
         |> Map.put(:deck, deck)}
      else
        {:error, game}
      end
    else
      {:error, game}
    end
  end

  defp deck_non_empty?(deck) do
    List.flatten(deck) != []
  end

  @impl Games
  def can_move?(to, from) when is_list(from) do
    can_move?(to, List.last(from))
  end

  def can_move?(nil, {_, rank}) do
    rank == List.last(Games.ranks())
  end

  def can_move?(nil, _from_card), do: false

  def can_move?(_to_card, nil), do: false

  def can_move?({suit, _}, {suit, _}), do: false

  def can_move?({_, rank}, {_, rank}), do: false

  # to, from
  def can_move?({to_col_suit, to_col_rank}, {from_suit, from_rank}) do
    with false <- from_rank == List.first(Games.ranks()),
         1 <- Games.rank_index(to_col_rank) - Games.rank_index(from_rank),
         true <- suits_of_different_color?(from_suit, to_col_suit) do
      true
    else
      _result -> false
    end
  end

  defp suits_of_different_color?(suit, suit), do: false

  defp suits_of_different_color?(suit1, suit2) do
    if suit1 in @black_suits do
      suit2 in @red_suits
    else
      suit2 in @black_suits
    end
  end
end
