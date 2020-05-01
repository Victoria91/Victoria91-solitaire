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
    Games.take_cards_to_col(game, col_num, 6, 5)
  end

  defp take_cards_to_col(game, col_num) do
    Games.take_cards_to_col(game, col_num, 5, 4)
  end

  def shuffle(suits_count) do
    %{%Games{} | deck: suits_count |> deck() |> Enum.shuffle()}
  end

  def deck(suit_count) do
    Enum.flat_map(Games.ranks(), fn r ->
      Enum.map(Enum.take(Games.suits(), suit_count), fn s -> {s, r} end)
    end)
    |> List.duplicate(
      floor(ranks_length() * length(Games.suits()) * 2 / (ranks_length() * suit_count))
    )
    |> List.flatten()
  end

  defp ranks_length, do: length(Games.ranks())

  @impl Games
  def move_to_foundation(game, :deck), do: game

  def move_to_foundation(%{cols: cols} = game, col_num) do
    %{cards: [from | _] = cards} = Enum.at(cols, col_num)
    cards_to_move = Enum.take(cards, ranks_length())

    with true <- cards_in_one_suit?(cards_to_move),
         true <- cards_in_sequence?(cards_to_move) do
      Games.move_from_column_to_foundation(
        game,
        Games.suit(from),
        col_num,
        ranks_length(),
        Solitaire.Game.Spider.Foundation
      )
    else
      _ ->
        game
    end
  end

  @impl Games

  def move_from_deck(%{deck: [next | rest], cols: cols} = game, __) do
    if all_cols_are_non_empty?(cols) do
      next
      |> Enum.with_index()
      |> Enum.reduce(game, fn {num, i}, game ->
        col = %{cards: cards} = Enum.at(cols, i)
        new_col = %{col | cards: [num | cards]}

        game
        |> Games.update_cols(i, new_col)
      end)
      |> Map.put(:deck, rest)
    else
      game
    end
  end

  def move_from_deck(game, _), do: game

  def change(game), do: game

  defp all_cols_are_non_empty?(cols) do
    cols
    |> Enum.map(& &1.cards)
    |> Enum.find(&(&1 == [])) ==
      nil
  end

  @impl Games
  def move_from_column(game, from_col_num, to_col_num) do
    Games.move_cards_from_column(
      game,
      from_col_num,
      to_col_num,
      &can_move?(&1, &2)
    )
  end

  @impl Games
  def can_move?(nil, _), do: true

  def can_move?(_, nil), do: false

  def can_move?({_, rank}, {_, rank}), do: false

  # to, from
  def can_move?(to, cards_for_move) do
    with true <- cards_in_one_suit?(cards_for_move),
         true <- cards_in_sequence?(cards_for_move ++ [to]) do
      true
    else
      _ -> false
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
