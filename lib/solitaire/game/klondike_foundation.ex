defmodule Solitaire.Game.Klondike.Foundation do
  alias Solitaire.Games

  @ranks Games.ranks()
  @first_rank List.first(@ranks)

  @spec push(map, binary) :: map
  def push(foundation, suit) do
    case Map.fetch!(foundation, suit) do
      nil -> %{foundation | suit => List.first(@ranks)}
      rank -> %{foundation | suit => next_rank(rank)}
    end
  end

  def pop(foundation, suit) do
    case Map.fetch!(foundation, suit) do
      nil -> foundation
      @first_rank -> foundation
      rank -> %{foundation | suit => prev_rank(rank)}
    end
  end

  defp next_rank(rank) do
    i = Enum.find_index(@ranks, &(&1 == rank))
    Enum.at(@ranks, i + 1)
  end

  defp prev_rank(rank) do
    i = Enum.find_index(@ranks, &(&1 == rank))
    Enum.at(@ranks, i - 1)
  end
end
