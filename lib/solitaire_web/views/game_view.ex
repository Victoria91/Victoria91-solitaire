defmodule SolitaireWeb.GameView do
  @card_offsets [0, 4, 8]
  @rank_classes %{3 => "three", :K => "king"}

  use SolitaireWeb, :view

  defdelegate ranks, to: Solitaire.Games

  def rank(card), do: elem(card, 1)

  def suit(card), do: elem(card, 0)

  def card_rank_class(card) do
    case Map.fetch(@rank_classes, rank(card)) do
      {:ok, class} -> class
      _ -> ""
    end
  end

  def left_style(i), do: Enum.take(@card_offsets, i)

  def current(deck) do
    deck |> List.first() |> List.first()
  end

  def deck_top(deck) do
    List.first(deck)
  end
end
