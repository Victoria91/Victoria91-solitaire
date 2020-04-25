defmodule Solitaire.Game.Spider.Foundation do
  @spec push(map, binary) :: map
  def push(foundation, suit) do
    prev_count = Map.fetch!(foundation, suit) || 0
    %{foundation | suit => prev_count + 1}
  end
end
