defmodule SolitaireWeb.PageController do
  alias Solitaire.Game.Klondike

  use SolitaireWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def can_move(conn, %{
        "to_suit" => to_suit,
        "to_rank" => to_rank,
        "from_suit" => from_suit,
        "from_rank" => from_rank
      }) do
    can_move =
      Klondike.can_move?(
        {String.to_existing_atom(to_suit), convert_to_rank(to_rank)},
        {String.to_existing_atom(from_suit), convert_to_rank(from_rank)}
      )

    text(conn, can_move)
  end

  defp convert_to_rank(rank) do
    case Integer.parse(rank) do
      {integer, ""} -> integer
      :error -> String.to_existing_atom(rank)
    end
  end
end
