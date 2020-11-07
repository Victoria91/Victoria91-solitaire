defmodule Solitaire.Games do
  defstruct cols: [],
            deck: [],
            deck_length: 8,
            from: nil,
            foundation: %{
              spade: %{rank: nil, from: nil, prev: nil, count: 0},
              diamond: %{rank: nil, from: nil, prev: nil, count: 0},
              heart: %{rank: nil, from: nil, prev: nil, count: 0},
              club: %{rank: nil, from: nil, prev: nil, count: 0}
            }

  @ranks [:A, 2, 3, 4, 5, 6, 7, 8, 9, 10, :J, :D, :K]
  @suits ~w(spade heart diamond club)a

  @callback load_game(keyword) :: Games.t()
  @callback can_move?(tuple, list(tuple)) :: boolean
  @callback move_from_deck(Games.t(), any) :: {:ok, Games.t()} | {:error, Games.t()}
  @callback move_to_foundation(Games.t(), integer, keyword) :: Games.t()

  @callback move_from_column(Games.t(), {integer, integer}, integer) ::
              {:ok, Games.t()} | {:error, Games.t()}

  def ranks, do: @ranks
  def suits, do: @suits

  def black_suits, do: ~w(spade club)a
  def red_suits, do: ~w(diamond heart)a

  @doc """
    Возвращает tuple, первый элемент которого - полученные `count` карт из колоды,
    второй - оставшаяся колода
  """
  @spec take_card_from_deck(list(tuple), integer) :: {[tuple], [tuple]}
  def take_card_from_deck(deck, count) do
    Enum.split(deck, count)
  end

  @doc """
    Разбивает колоду на массив из `count` карт
  """
  @spec split_deck_by(list(tuple), pos_integer) :: [[any]]
  def split_deck_by(deck, count) do
    Enum.chunk_every(deck, count)
  end

  @doc """
    Обновляет состояние игры %Games{}, беря из колоды card_count карт в col_num столбец
  """
  @spec take_cards_to_col(%{cols: [any], deck: [tuple]}, integer, integer, integer) :: %{
          cols: [...],
          deck: [tuple]
        }
  def take_cards_to_col(%{deck: deck, cols: cols} = game, col_num, card_count, unplayed_count) do
    {cards, rest} = take_card_from_deck(deck, card_count)

    game
    |> Map.put(:deck, rest)
    |> Map.put(:cols, List.insert_at(cols, col_num, %{cards: cards, unplayed: unplayed_count}))
  end

  def suit({suit, _}), do: suit
  def rank({_, rank}), do: rank

  def rank_index(rank), do: Enum.find_index(@ranks, &(&1 == rank))

  def update_cols(%{cols: cols} = game, col_index, col_value) do
    %{game | cols: List.replace_at(cols, col_index, col_value)}
  end

  @spec move_cards_from_column(%{cols: any}, any, integer, (any, any -> any)) ::
          {:error, %{cols: any}} | {:ok, %{cols: [any]}}
  def move_cards_from_column(
        %{cols: cols} = game,
        {from_col_num, index},
        to_col_num,
        can_move_function
      ) do
    from_column = %{cards: from_cards, unplayed: unplayed} = Enum.at(cols, from_col_num)

    to_column = %{cards: to_cards} = Enum.at(cols, to_col_num)
    to = List.first(to_cards)

    for_move_count = length(from_cards) - index

    {new_from_column, removed_cards} = take_cards_from_column(from_column, for_move_count)

    if can_move_function.(to, removed_cards) && index > unplayed - 1 do
      to_column = %{to_column | cards: removed_cards ++ to_cards}

      {:ok,
       game
       |> update_cols(from_col_num, new_from_column)
       |> update_cols(to_col_num, to_column)}
    else
      {:error, game}
    end
  end

  @spec take_cards_from_column(%{cards: any, unplayed: any}, integer) ::
          {%{cards: [any], unplayed: any}, [any]}
  def take_cards_from_column(%{cards: cards, unplayed: unplayed}, count) do
    {cards_to_move, rest_cards} = Enum.split(cards, count)

    {%{
       cards: rest_cards,
       unplayed: maybe_decrease_unplayed(length(rest_cards), unplayed)
     }, cards_to_move}
  end

  def take_card_from_column(%{cards: [_ | rest_cards], unplayed: unplayed}) do
    %{cards: rest_cards, unplayed: maybe_decrease_unplayed(length(rest_cards), unplayed)}
  end

  def move_from_column_to_foundation(
        %{foundation: foundation, cols: cols} = game,
        suit,
        from_col_num,
        cards_count,
        from,
        module
      ) do
    {new_from_column, _moved_cards} =
      take_cards_from_column(Enum.at(cols, from_col_num), cards_count)

    game
    |> Map.put(:foundation, module.push(foundation, suit, from))
    |> update_cols(from_col_num, new_from_column)
  end

  defp maybe_decrease_unplayed(_length, 0), do: 0

  defp maybe_decrease_unplayed(length_of_cards_rest, unplayed)
       when length_of_cards_rest > unplayed,
       do: unplayed

  defp maybe_decrease_unplayed(_length, unplayed), do: unplayed - 1
end
