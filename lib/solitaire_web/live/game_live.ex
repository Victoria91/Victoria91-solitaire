defmodule SolitaireWeb.GameLive do
  use Phoenix.LiveView
  alias Solitaire.Game

  def render(assigns) do
    # IO.inspect(assigns, label: "assigns")
    Phoenix.View.render(SolitaireWeb.GameView, "index.html", assigns)

    # ~L"""
    # Current count: <%= @count %> <button phx-click="dec">-</button> <button phx-click="inc">+</button>
    # """
  end

  def mount(_params, socket) do
    {:ok, pid} = Game.start_link([])
    state = Game.state(pid)

    socket = assign_game_state(socket, state, pid)

    {:ok, socket}
  end

  def handle_event("change", _val, socket) do
    pid = socket.assigns.pid

    state = Game.change(pid)

    new_socket = assign_game_state(socket, state, pid)

    {:noreply, new_socket}
  end

  defp assign_game_state(socket, state, pid) do
    assign(socket, :cols, state.cols)
    |> assign(:deck, state.deck)
    |> assign(:current, state.current)
    |> assign(:pid, pid)
  end
end
