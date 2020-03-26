defmodule SolitaireWeb.GameView do
  @rank_classes %{"3" => "three", "K" => "king"}

  use SolitaireWeb, :view

  def rank(card), do: elem(card, 1)

  def suit(card), do: elem(card, 0)

  def card_rank_class(card) do
    case Map.fetch(@rank_classes, rank(card)) do
      {:ok, class} -> class
      _ -> ""
    end
  end
end
