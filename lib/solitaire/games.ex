defmodule Solitaire.Games do
  defstruct cols: [],
            deck: [],
            deck_length: 8,
            type: nil,
            token: nil,
            previous: %{},
            suit_count: nil,
            unplayed_fnd_cols_count: 0,
            foundation: %{
              spade: %{rank: nil, from: nil, prev: nil},
              diamond: %{rank: nil, from: nil, prev: nil},
              heart: %{rank: nil, from: nil, prev: nil},
              club: %{rank: nil, from: nil, prev: nil},
              sorted: []
            }

  @ranks [:A, 2, 3, 4, 5, 6, 7, 8, 9, 10, :J, :D, :K]
  @suits ~w(spade heart diamond club)a

  @callback load_game(integer()) :: Games.t()
  @callback can_move?(tuple, list(tuple)) :: boolean
  @callback move_from_deck(Games.t(), any) :: {:ok, Games.t()} | {:error, Games.t()}
  @callback move_to_foundation(Games.t(), integer, keyword) :: Games.t()

  @callback move_from_column(Games.t(), {integer, integer}, integer) ::
              {:ok, Games.t()} | {:error, Games.t()}

  @callback change(Games.t()) :: Games.t()

  @spec ranks :: [:A | :D | :J | :K | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10, ...]
  def ranks, do: @ranks
  def suits, do: @suits

  defimpl Jason.Encoder, for: Solitaire.Games do
    def encode(
          %{
            foundation: foundation,
            cols: cols,
            deck: deck,
            type: type,
            suit_count: suit_count,
            deck_length: deck_length
          },
          _options
        ) do
      Jason.encode!(%{
        columns:
          Enum.map(cols, fn %{cards: cards} = map ->
            %{map | cards: convert_keyword_to_list(cards)}
          end),
        type: type,
        suit_count: suit_count,
        sorted: foundation[:sorted],
        deck_length: deck_length,
        foundation: convert_to_string(foundation),
        deck: deck |> Enum.map(&convert_keyword_to_list/1) |> List.first()
      })
    end

    defp convert_to_string(map) do
      Map.new(map, fn
        {k, %{rank: rank} = foundation} ->
          {k,
           foundation
           |> Map.put(:rank, convert_rank_to_string(rank))
           |> Map.put(:prev, convert_rank_to_string(foundation[:prev]))}

        {:sorted, suits} ->
          {:sorted, Enum.map(suits, &convert_rank_to_string/1)}
      end)
    end

    defp convert_rank_to_string(nil), do: nil

    defp convert_rank_to_string(rank) when is_atom(rank) do
      Atom.to_string(rank)
    end

    defp convert_rank_to_string(rank) when is_integer(rank) do
      Integer.to_string(rank)
    end

    defp convert_keyword_to_list(kw) do
      Enum.map(kw, fn
        [] -> []
        {k, v} -> [k, v]
      end)
    end
  end

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
  @spec take_cards_to_col(%{cols: [any], deck: [tuple]}, integer, integer, integer, integer) :: %{
          cols: [...],
          deck: [tuple]
        }
  def take_cards_to_col(
        %{deck: deck, cols: cols} = game,
        col_num,
        card_count,
        unplayed_count,
        moveable_count
      ) do
    {cards, rest} = take_card_from_deck(deck, card_count)

    game
    |> Map.put(:deck, rest)
    |> Map.put(
      :cols,
      List.insert_at(cols, col_num, %{
        cards: cards,
        unplayed: unplayed_count,
        moveable: moveable_count
      })
    )
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
  def take_cards_from_column(%{cards: cards, unplayed: unplayed} = column, count) do
    {cards_to_move, rest_cards} = Enum.split(cards, count)

    {
      Map.merge(column, %{
        cards: rest_cards,
        unplayed: maybe_decrease_unplayed(length(rest_cards), unplayed)
      }),
      cards_to_move
    }
  end

  def take_card_from_column(%{cards: [_ | rest_cards], unplayed: unplayed} = column) do
    Map.merge(column, %{
      cards: rest_cards,
      unplayed: maybe_decrease_unplayed(length(rest_cards), unplayed)
    })
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
