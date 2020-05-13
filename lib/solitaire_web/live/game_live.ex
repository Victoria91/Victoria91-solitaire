defmodule SolitaireWeb.GameLive do
  use Phoenix.LiveView
  alias Solitaire.Game.Server, as: GameServer

  @spec render([{any, any}] | map) :: any
  def render(assigns) do
    Phoenix.View.render(SolitaireWeb.GameView, "index.html", assigns)
  end

  def mount(_params, params, socket) do
    params |> IO.inspect()

    token = params["_csrf_token"]

    start_unless_started(token)

    Phoenix.PubSub.subscribe(Solitaire.PubSub, "game:#{token}")

    state = GameServer.state(token)

    socket =
      assign_game_state(socket, state, token)
      |> assign(:move_from_deck, false)
      |> assign(:pop, false)
      |> assign(:move_from_column, false)
      |> assign(:move_from_index, false)
      |> assign(:choose_game, false)

    {:ok, socket}
  end

  defp start_unless_started(token) do
    case GameServer.start_link(%{token: token}) |> IO.inspect(label: "START LINK RES") do
      {:error, _} -> :error
      result -> result
    end
  end

  def handle_event("choose_new_game", _, socket) do
    {:noreply, assign(socket, :choose_game, true)}
  end

  def handle_event("start_new_game", %{"type" => type, "count" => count}, socket) do
    token = socket.assigns[:token]

    GameServer.restart(token, %{type: type, count: count})
    state = GameServer.state(token)

    new_socket =
      assign_game_state(socket, GameServer.state(token), token) |> assign(:choose_game, false)

    broadcast_game_state(token, state)
    {:noreply, new_socket}
  end

  def handle_event("move_from_deck", _val, socket) do
    new_socket =
      if socket.assigns[:type] == :klondike do
        assign(socket, :move_from_deck, true)
      else
        token = socket.assigns[:token]

        state = GameServer.move_from_deck(token, [])
        broadcast_game_state(token, state)
        assign_game_state(socket, state, token)
      end

    IO.inspect("SELECTED")

    {:noreply, new_socket}
  end

  def handle_event("put", params, socket) do
    IO.inspect("put")
    token = socket.assigns[:token]

    cond do
      socket.assigns[:move_from_deck] ->
        game = GameServer.move_to_foundation(token, :deck)
        new_socket = assign_game_state(socket, game, token)
        broadcast_game_state(token, game)

        {:noreply, new_socket}

      from_column = socket.assigns[:move_from_column] ->
        token = socket.assigns.token |> IO.inspect()
        state = GameServer.move_to_foundation(token, from_column)
        new_socket = assign_game_state(socket, state, token) |> assign(:move_from_column, false)
        broadcast_game_state(token, state)

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
        token = socket.assigns.token
        state = GameServer.move_from_foundation(token, suit, column)
        new_socket = assign_game_state(socket, state, token) |> assign(:pop, false)
        broadcast_game_state(token, state)

        {:noreply, new_socket}

      socket.assigns[:move_from_deck] ->
        token = socket.assigns.token
        state = GameServer.move_from_deck(token, column)
        new_socket = assign_game_state(socket, state, token) |> assign(:move_from_deck, false)
        broadcast_game_state(token, state)

        {:noreply, new_socket}

      (from_col_num = socket.assigns[:move_from_column]) && socket.assigns[:move_from_index] ->
        token = socket.assigns.token |> IO.inspect()

        state =
          GameServer.move_from_column(
            token,
            {from_col_num, socket.assigns[:move_from_index]},
            column
          )

        new_socket =
          assign_game_state(socket, state, token)
          |> assign(:move_from_column, false)
          |> assign(:move_from_index, false)

        broadcast_game_state(token, state)

        {:noreply, new_socket}

      params["index"] ->
        new_socket =
          socket
          |> assign(:move_from_column, column)
          |> assign(:move_from_index, parse_integer!(params["index"]))

        {:noreply, new_socket}

      true ->
        {:noreply, socket}
    end
  end

  @spec handle_event(<<_::48>>, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_event("change", _val, socket) do
    token = socket.assigns.token

    state = GameServer.change(token)

    broadcast_game_state(token, state)

    new_socket =
      assign_game_state(socket, state, token)
      |> assign(:move_from_deck, false)

    {:noreply, new_socket}
  end

  defp broadcast_game_state(token, state) do
    Phoenix.PubSub.broadcast_from!(Solitaire.PubSub, self(), "game:#{token}", {:tick, state})
  end

  defp parse_integer!(value) do
    {int, _} = Integer.parse(value)
    int
  end

  def handle_info({:tick, game}, socket) do
    token = socket.assigns.token

    new_socket = assign_game_state(socket, game, token)
    {:noreply, new_socket}
  end

  defp assign_game_state(socket, state, token) do
    assign(socket, :cols, state.cols)
    |> assign(:deck_length, state.deck_length)
    |> assign(:deck, state.deck)
    |> assign(:foundation, state.foundation)
    |> assign(:type, state.type)
    |> assign(:token, token)
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
