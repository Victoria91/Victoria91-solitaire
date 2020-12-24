defmodule Solitaire.Game.Spider do
  alias Solitaire.Games
  @behaviour Games

  @impl Games
  def load_game(suits_count) do
    game =
      %{deck: rest_deck} =
      Enum.reduce(0..9, shuffle(suits_count), fn i, game -> take_cards_to_col(game, i) end)

    Map.put(game, :deck, Games.split_deck_by(rest_deck, 10) ++ [[]])
  end

  defp take_cards_to_col(game, col_num) when col_num in 0..3 do
    Games.take_cards_to_col(game, col_num, 6, 5, 1)
  end

  defp take_cards_to_col(game, col_num) do
    Games.take_cards_to_col(game, col_num, 5, 4, 1)
  end

  def shuffle(suits_count) do
    %{%Games{} | deck: suits_count |> deck() |> Enum.shuffle()}
  end

  def deck(suit_count) do
    Games.ranks()
    |> Enum.flat_map(fn r ->
      Enum.map(Enum.take(Games.suits(), suit_count), fn s -> {s, r} end)
    end)
    |> List.duplicate(
      floor(ranks_length() * length(Games.suits()) * 2 / (ranks_length() * suit_count))
    )
    |> List.flatten()
  end

  defp ranks_length, do: length(Games.ranks())

  @impl Games
  def move_to_foundation(game, :deck, _opts), do: game

  def move_to_foundation(%{cols: cols} = game, col_num, _opts) do
    %{cards: cards} = Enum.at(cols, col_num)
    cards_to_move = Enum.take(cards, ranks_length())

    with from when not is_nil(from) <- List.first(cards),
         true <- length(cards_to_move) == ranks_length(),
         true <- cards_in_one_suit?(cards_to_move),
         true <- cards_in_sequence?(cards_to_move) do
      update_moveable(
        Games.move_from_column_to_foundation(
          game,
          Games.suit(from),
          col_num,
          ranks_length(),
          ["column", col_num],
          Solitaire.Game.Spider.Foundation
        ),
        [col_num]
      )
    else
      _result ->
        game
    end
  end

  @impl Games

  def move_from_deck(%{deck: [next | rest], cols: cols} = game, __) do
    if all_cols_are_non_empty?(cols) do
      new_game =
        next
        |> Enum.with_index()
        |> Enum.reduce(game, fn {num, i}, game ->
          col = %{cards: cards} = Enum.at(cols, i)
          new_col = %{col | cards: [num | cards]}

          Games.update_cols(game, i, new_col)
        end)
        |> Map.put(:deck, rest)

      {:ok, update_moveable(new_game, 0..(length(cols) - 1))}
    else
      {:error, game}
    end
  end

  def move_from_deck(game, _param), do: {:error, game}

  @impl Games
  def change(game), do: game

  defp all_cols_are_non_empty?(cols) do
    cols
    |> Enum.map(& &1.cards)
    |> Enum.find(&(&1 == [])) ==
      nil
  end

  @impl Games
  def move_from_column(game, {column_index, _card_index} = from_col_num, to_col_num) do
    case Games.move_cards_from_column(
           game,
           from_col_num,
           to_col_num,
           &can_move?(&1, &2)
         ) do
      {:ok, game} -> {:ok, update_moveable(game, [column_index, to_col_num])}
      {:error, game} -> {:error, game}
    end
  end

  defp update_moveable(game, indexes) do
    Enum.reduce(indexes, game, fn x, %{cols: cols} = new_game ->
      column = Enum.at(cols, x)

      new_cols =
        List.replace_at(cols, x, %{column | moveable: find_unmoveable_index(column[:cards])})

      Map.put(new_game, :cols, new_cols)
    end)
  end

  defp find_unmoveable_index(cards) do
    Enum.reduce_while(cards, 0, fn _card, acc ->
      if !cards_in_one_suit?(Enum.take(cards, acc + 1)) ||
           !cards_in_sequence?(Enum.take(cards, acc + 1)) do
        {:halt, acc}
      else
        {:cont, acc + 1}
      end
    end)
  end

  @impl Games
  def can_move?(nil, _from_card), do: true

  def can_move?(_to_card, nil), do: false

  def can_move?({_, rank}, {_, rank}), do: false

  # to, from
  def can_move?(to, cards_for_move) do
    with true <- cards_in_one_suit?(cards_for_move),
         true <- cards_in_sequence?(cards_for_move ++ [to]) do
      true
    else
      _result -> false
    end
  end

  defp cards_in_one_suit?(cards) do
    cards |> Enum.map(fn {suit, _} -> suit end) |> Enum.uniq() |> length() == 1
  end

  defp cards_in_sequence?(cards) do
    cards
    |> Enum.slice(0..-2)
    |> Enum.with_index()
    |> Enum.take_while(fn {{_suit, cur_rank}, index} ->
      {_, rank} = Enum.at(cards, index + 1)
      Games.rank_index(cur_rank) == Games.rank_index(rank) - 1
    end)
    |> length() ==
      length(cards) - 1
  end
end
