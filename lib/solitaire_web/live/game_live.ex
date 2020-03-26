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

  def handle_event("move_from_deck", _val, socket) do
    pid = socket.assigns.pid

    new_socket = socket |> assign(:move_from_deck, true)

    IO.inspect("SELECTED")

    # state = Game.move_from_deck(pid, 2)
    # new_socket = assign_game_state(socket, state, pid)

    {:noreply, new_socket}
  end

  def handle_event("move", %{"column" => column} = params, socket) do
    params |> IO.inspect()
    column |> IO.inspect()

    if socket.assigns[:move_from_deck] do
      pid = socket.assigns.pid
      {column, _} = Integer.parse(column)
      state = Game.move_from_deck(pid, column)
      new_socket = assign_game_state(socket, state, pid) |> assign(:move_from_deck, true)

      {:noreply, new_socket}
    else
      {:noreply, socket}
    end
  end

  @spec handle_event(<<_::48>>, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
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
