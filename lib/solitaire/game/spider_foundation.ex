defmodule Solitaire.Game.Spider.Foundation do
  @spec push(map, binary, list) :: map
  def push(foundation, suit, from) do
    prev_count = get_in(foundation, [suit, :count]) || 0

    foundation
    |> Map.put(suit, %{count: prev_count + 1, from: from, rank: :A})
    |> Map.put(:sorted, (foundation[:sorted] || []) ++ [suit])
  end
end
