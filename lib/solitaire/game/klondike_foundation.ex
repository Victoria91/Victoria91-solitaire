defmodule Solitaire.Game.Klondike.Foundation do
  alias Solitaire.Games

  @ranks Games.ranks()
  @first_rank List.first(@ranks)

  @spec push(map, binary, list) :: map
  def push(foundation, suit, from) do
    case get_in(foundation, [suit, :rank]) do
      nil -> Map.put(foundation, suit, %{rank: List.first(@ranks), from: from, prev: nil})
      rank -> Map.put(foundation, suit, %{rank: next_rank(rank), from: from, prev: rank})
    end
  end

  def pop(foundation, suit) do
    case get_in(foundation, [suit, :rank]) do
      nil ->
        foundation

      @first_rank ->
        foundation

      rank ->
        new_rank = prev_rank(rank)

        %{foundation | suit => %{from: nil, rank: new_rank, prev: prev_rank(new_rank)}}
    end
  end

  defp next_rank(rank) do
    Enum.at(@ranks, find_rank_index(rank) + 1)
  end

  defp prev_rank(rank) do
    Enum.at(@ranks, find_rank_index(rank) - 1)
  end

  def can_automove?(_foundation, _rank, _suit, false), do: true

  def can_automove?(_foundation, :A, _suit, _true), do: true

  def can_automove?(foundation, rank, suit, true) do
    if suit in Games.red_suits() do
      all_cards_are_less(Games.black_suits(), foundation, rank)
    else
      all_cards_are_less(Games.red_suits(), foundation, rank)
    end
  end

  defp all_cards_are_less(suits, foundation, foundation_rank) do
    other_color_foundation_ranks =
      suits
      |> Enum.map(&fetch_rank_from_foundation(foundation, &1))
      |> Enum.reject(&is_nil/1)

    if length(other_color_foundation_ranks) < 2 do
      false
    else
      foundation_rank_index = find_rank_index(foundation_rank)

      other_color_foundation_ranks
      |> Enum.map(&find_rank_index/1)
      |> Enum.filter(&(&1 < foundation_rank_index))
      |> Enum.empty?() ==
        true
    end
  end

  defp find_rank_index(rank), do: Enum.find_index(@ranks, &(&1 == rank))

  def fetch_rank_from_foundation(foundation, suit) do
    get_in(foundation, [suit, :rank])
  end
end
