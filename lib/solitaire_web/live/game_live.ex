defmodule SolitaireWeb.GameLive do
  use Phoenix.LiveView
  alias Solitaire.Game.Server, as: GameServer
  alias Solitaire.Game.Supervisor, as: GameSupervisor

  require Logger

  def render(assigns) do
    Phoenix.View.render(SolitaireWeb.GameView, "index.html", assigns)
  end

  def mount(_params, session, socket) do
    Logger.info("Session data: #{inspect(session)}")

    token = session["_csrf_token"]

    start_unless_started(token)

    Phoenix.PubSub.subscribe(Solitaire.PubSub, "game:#{token}")

    state = GameServer.state(token)

    socket =
      socket
      |> assign_game_state(state, token)
      |> assign(:move_from_deck, false)
      |> assign(:pop, false)
      |> assign(:move_from_column, false)
      |> assign(:move_from_index, false)
      |> assign(:choose_game, false)

    {:ok, socket}
  end

  defp start_unless_started(token) do
    start_game_res = GameSupervisor.start_game(%{token: token})
    Logger.info("Start game result for token: #{inspect(token)}: #{inspect(start_game_res)}")

    case start_game_res do
      {:error, _} -> :error
      result -> result
    end
  end

  def handle_event("choose_new_game", _params, socket) do
    {:noreply, assign(socket, :choose_game, true)}
  end

  def handle_event(
        "start_new_game",
        %{"type" => type, "count" => count},
        %{assigns: %{token: token}} = socket
      ) do
    GameSupervisor.restart_game(token, %{type: type, suit_count: count})

    state = GameServer.state(token)

    new_socket = socket |> assign_game_state(state, token) |> assign(:choose_game, false)

    broadcast_game_state(token, state)
    {:noreply, new_socket}
  end

  def handle_event("move_from_deck", _params, %{assigns: %{type: :klondike}} = socket) do
    {:noreply, assign(socket, :move_from_deck, true)}
  end

  def handle_event("move_from_deck", _params, %{assigns: %{token: token}} = socket) do
    case GameServer.move_from_deck(token, []) do
      {:ok, new_state} ->
        broadcast_game_state(token, new_state)
        {:noreply, assign_game_state(socket, new_state, token)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("put", _params, %{assigns: %{move_from_deck: true, token: token}} = socket) do
    game = GameServer.move_to_foundation(token, :deck)
    new_socket = assign_game_state(socket, game, token)
    broadcast_game_state(token, game)

    {:noreply, new_socket}
  end

  def handle_event(
        "put",
        _params,
        %{assigns: %{move_from_column: from_column, token: token}} = socket
      )
      when is_integer(from_column) do
    state = GameServer.move_to_foundation(token, from_column)
    new_socket = assign(assign_game_state(socket, state, token), :move_from_column, false)
    broadcast_game_state(token, state)

    {:noreply, new_socket}
  end

  def handle_event("put", %{"suit" => suit}, socket) do
    {:noreply, assign(socket, :pop, suit)}
  end

  def handle_event(event, %{"column" => column} = params, socket) when is_binary(column) do
    new_params = %{params | "column" => parse_integer!(column)}
    handle_event(event, new_params, socket)
  end

  @doc """
    Складывание карты из базы в столбцы
  """
  def handle_event(
        "move",
        %{"column" => column},
        %{assigns: %{token: token, pop: suit}} = socket
      )
      when is_binary(suit) do
    state = GameServer.move_from_foundation(token, suit, column)
    new_socket = assign(assign_game_state(socket, state, token), :pop, false)
    broadcast_game_state(token, state)

    {:noreply, new_socket}
  end

  @doc """
    Складывание карты из колоды в столбец
  """
  def handle_event(
        "move",
        %{"column" => column},
        %{assigns: %{token: token, move_from_deck: true}} = socket
      ) do
    case GameServer.move_from_deck(token, column) do
      {:ok, new_state} ->
        new_socket = assign(assign_game_state(socket, new_state, token), :move_from_deck, false)
        broadcast_game_state(token, new_state)
        {:noreply, new_socket}

      {:error, _} ->
        {:noreply, assign(socket, :move_from_deck, false)}
    end
  end

  @doc """
    Перекладывание карты из одного столбца в другой
  """
  def handle_event(
        "move",
        %{"column" => column},
        %{
          assigns: %{
            token: token,
            move_from_column: from_col_num,
            move_from_index: move_from_index
          }
        } = socket
      )
      when is_integer(from_col_num) and is_integer(move_from_index) do
    case GameServer.move_from_column(
           token,
           {from_col_num, socket.assigns[:move_from_index]},
           column
         ) do
      {:ok, state} ->
        new_socket =
          socket
          |> assign_game_state(state, token)
          |> assign(:move_from_column, false)
          |> assign(:move_from_index, false)

        broadcast_game_state(token, state)

        {:noreply, new_socket}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:move_from_column, false)
         |> assign(:move_from_index, false)}
    end
  end

  @doc """
    Сохранение в сокете выбранного столбца
  """
  def handle_event(
        "move",
        %{"index" => index, "column" => column},
        socket
      ) do
    new_socket =
      socket
      |> assign(:move_from_column, column)
      |> assign(:move_from_index, parse_integer!(index))

    {:noreply, new_socket}
  end

  def handle_event("change", _val, %{assigns: %{token: token}} = socket) do
    state = GameServer.change(token)

    broadcast_game_state(token, state)

    new_socket = assign(assign_game_state(socket, state, token), :move_from_deck, false)

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
    socket
    |> assign(:cols, state.cols)
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
        {_suit, %{count: count}}, acc when not is_nil(count) ->
          count + acc

        _val, acc ->
          acc
      end)

    assign(socket, :unplayed_fnd_cols_count, 8 - played_count)
  end

  defp assign_blank_fnd_cols_count(socket, _game_state),
    do: assign(socket, :unplayed_fnd_cols_count, 0)
end
