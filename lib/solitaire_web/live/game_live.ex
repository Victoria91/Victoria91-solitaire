defmodule SolitaireWeb.GameLive do
  use Phoenix.LiveView
  alias Solitaire.Game.Sever, as: GameServer

  def render(assigns) do
    Phoenix.View.render(SolitaireWeb.GameView, "index.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok, pid} = GameServer.start_link([])
    Phoenix.PubSub.subscribe(Solitaire.PubSub, "game:#{inspect(pid)}")

    state = GameServer.state(pid)
    pid |> IO.inspect(label: "pid")

    socket =
      assign_game_state(socket, state, pid)
      |> assign(:move_from_deck, false)
      |> assign(:pop, false)
      |> assign(:move_from_column, false)

    {:ok, socket}
  end

  def handle_event("move_from_deck", _val, socket) do
    new_socket = socket |> assign(:move_from_deck, true)

    IO.inspect("SELECTED")

    {:noreply, new_socket}
  end

  def handle_event("put", %{"suit" => suit}, socket) do
    pid = socket.assigns[:pid]

    cond do
      socket.assigns[:move_from_deck] ->
        game = GameServer.move_to_foundation(pid, :deck)
        new_socket = assign_game_state(socket, game, pid)
        {:noreply, new_socket}

      from_column = socket.assigns[:move_from_column] ->
        pid = socket.assigns.pid |> IO.inspect()
        state = GameServer.move_to_foundation(pid, from_column)
        new_socket = assign_game_state(socket, state, pid) |> assign(:move_from_column, false)

        {:noreply, new_socket}

      true ->
        new_socket = socket |> assign(:pop, suit)

        {:noreply, new_socket}
    end
  end

  def handle_info({:tick, game}, socket) do
    pid = socket.assigns.pid

    new_socket = assign_game_state(socket, game, pid)
    {:noreply, new_socket}
  end

  def handle_event("move", %{"column" => column}, socket) do
    {column, _} = Integer.parse(column)

    cond do
      suit = socket.assigns[:pop] ->
        pid = socket.assigns.pid
        state = GameServer.move_from_foundation(pid, suit, column)
        new_socket = assign_game_state(socket, state, pid) |> assign(:pop, false)

        {:noreply, new_socket}

      socket.assigns[:move_from_deck] ->
        pid = socket.assigns.pid
        state = GameServer.move_from_deck(pid, column)
        new_socket = assign_game_state(socket, state, pid) |> assign(:move_from_deck, false)

        {:noreply, new_socket}

      from_column = socket.assigns[:move_from_column] ->
        pid = socket.assigns.pid |> IO.inspect()
        state = GameServer.move_from_column(pid, from_column, column)
        new_socket = assign_game_state(socket, state, pid) |> assign(:move_from_column, false)

        {:noreply, new_socket}

      true ->
        new_socket = socket |> assign(:move_from_column, column)
        {:noreply, new_socket}
    end
  end

  @spec handle_event(<<_::48>>, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_event("change", _val, socket) do
    pid = socket.assigns.pid

    state = GameServer.change(pid)

    new_socket = assign_game_state(socket, state, pid) |> assign(:move_from_deck, false)

    {:noreply, new_socket}
  end

  defp assign_game_state(socket, state, pid) do
    assign(socket, :cols, state.cols)
    |> assign(:deck_length, state.deck_length)
    |> assign(:deck, state.deck)
    |> assign(:foundation, state.foundation)
    |> assign(:pid, pid)
  end
end
