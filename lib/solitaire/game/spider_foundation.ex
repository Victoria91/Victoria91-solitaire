defmodule Solitaire.Game.Spider.Foundation do
  @spec push(map, binary, list) :: map
  def push(foundation, suit, from) do
    # prev_count = Map.fetch!(foundation, suit) || 0
    # %{foundation | suit => prev_count + 1}
    prev_count = get_in(foundation, [suit, :count]) || 0
    %{foundation | suit => %{count: prev_count + 1, from: from}}
  end
end
