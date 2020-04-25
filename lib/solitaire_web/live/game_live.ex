defmodule SolitaireWeb.GameLive do
  use Phoenix.LiveView
  alias Solitaire.Game.Sever, as: GameServer

  @spec render([{any, any}] | map) :: any
  def render(assigns) do
    Phoenix.View.render(SolitaireWeb.GameView, "index.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok, pid} = GameServer.start_link([])

    Phoenix.PubSub.subscribe(Solitaire.PubSub, "game:#{inspect(pid)}")

    pid |> IO.inspect(label: "PID")
    state = GameServer.state(pid)

    socket =
      assign_game_state(socket, state, pid)
      |> assign(:move_from_deck, false)
      |> assign(:pop, false)
      |> assign(:move_from_column, false)
      |> assign(:move_from_index, false)

    {:ok, socket}
  end

  def handle_event("move_from_deck", _val, socket) do
    new_socket =
      if socket.assigns[:type] == :klondike do
        assign(socket, :move_from_deck, true)
      else
        pid = socket.assigns[:pid]

        state = GameServer.move_from_deck(pid, [])
        assign_game_state(socket, state, pid)
      end

    IO.inspect("SELECTED")

    {:noreply, new_socket}
  end

  def handle_event("put", params, socket) do
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
        new_socket = socket |> assign(:pop, params["suit"])

        {:noreply, new_socket}
    end
  end

  def handle_event("move", %{"column" => column} = params, socket) do
    column = parse_integer!(column)

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

      (from_col_num = socket.assigns[:move_from_column]) && socket.assigns[:move_from_index] ->
        pid = socket.assigns.pid |> IO.inspect()

        state =
          GameServer.move_from_column(
            pid,
            {from_col_num, socket.assigns[:move_from_index]},
            column
          )

        new_socket =
          assign_game_state(socket, state, pid)
          |> assign(:move_from_column, false)
          |> assign(:move_from_index, false)

        {:noreply, new_socket}

      true ->
        new_socket =
          socket
          |> assign(:move_from_column, column)
          |> assign(:move_from_index, parse_integer!(params["index"]))

        {:noreply, new_socket}
    end
  end

  @spec handle_event(<<_::48>>, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_event("change", _val, socket) do
    pid = socket.assigns.pid

    state = GameServer.change(pid)

    new_socket =
      assign_game_state(socket, state, pid)
      |> assign(:move_from_deck, false)

    {:noreply, new_socket}
  end

  defp parse_integer!(value) do
    {int, _} = Integer.parse(value)
    int
  end

  def handle_info({:tick, game}, socket) do
    pid = socket.assigns.pid

    new_socket = assign_game_state(socket, game, pid)
    {:noreply, new_socket}
  end

  defp assign_game_state(socket, state, pid) do
    assign(socket, :cols, state.cols)
    |> assign(:deck_length, state.deck_length)
    |> assign(:deck, state.deck)
    |> assign(:foundation, state.foundation)
    |> assign(:type, state.type)
    |> assign(:pid, pid)
    |> assign_blank_fnd_cols_count(state)
  end

  defp assign_blank_fnd_cols_count(socket, %{foundation: foundation, type: :spider}) do
    played_count =
      Enum.reduce(foundation, 0, fn
        {_suit, count}, acc when not is_nil(count) -> count + acc
        _, acc -> acc
      end)

    socket
    |> assign(:unplayed_fnd_cols_count, 8 - played_count)
  end

  defp assign_blank_fnd_cols_count(socket, _), do: assign(socket, :unplayed_fnd_cols_count, 0)
end
