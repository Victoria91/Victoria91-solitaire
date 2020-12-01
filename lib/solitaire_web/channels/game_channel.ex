defmodule SolitaireWeb.GameChannel do
  use SolitaireWeb, :channel

  alias Solitaire.Game.Server, as: GameServer
  alias Solitaire.Game.Supervisor, as: GameSupervisor

  def join("game:" <> token, _params, socket) do
    case validate_token(token) do
      :ok ->
        GameSupervisor.start_game(%{token: token})

        state = GameServer.state(token)

        Phoenix.PubSub.subscribe(Solitaire.PubSub, "game:#{token}")

        {:ok, state, socket}

      :error ->
        {:error, :bad_token}
    end
  end

  defp validate_token(token) do
    if String.ends_with?(token, "==") && String.length(token) >= 24 do
      :ok
    else
      :error
    end
  end

  def handle_info({:tick, game}, socket) do
    broadcast!(socket, "update_game", game)

    {:noreply, socket}
  end

  def handle_info(:win, socket) do
    broadcast!(socket, "win", %{})
    {:noreply, socket}
  end

  def handle_out(event, payload, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  def handle_in(
        "start_new_game",
        %{"type" => type, "suit_count" => suit_count},
        %{topic: "game:" <> token} = socket
      ) do
    GameSupervisor.restart_game(
      token,
      %{type: type, suit_count: suit_count}
    )

    state = GameServer.state(token)

    {:reply, {:ok, state}, socket}
  end

  def handle_in(
        "move_from_foundation",
        %{"suit" => suit, "to_column" => to_column},
        %{topic: "game:" <> token} = socket
      ) do
    new_state = GameServer.move_from_foundation(token, suit, to_column)
    {:reply, {:ok, new_state}, socket}
  end

  def handle_in(
        "move_from_column",
        %{
          "from_card_index" => card_index,
          "from_column" => from_column,
          "to_column" => to_column
        },
        %{topic: "game:" <> token} = socket
      ) do
    case GameServer.move_from_column(token, {from_column, card_index}, to_column) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, socket}

      {:error, old_state} ->
        {:reply, {:error, old_state}, socket}
    end
  end

  def handle_in(
        "move_to_foundation_from_column",
        %{
          "from_column" => from_column
        },
        %{topic: "game:" <> token} = socket
      ) do
    new_state = GameServer.move_to_foundation(token, from_column)
    {:reply, {:ok, new_state}, socket}
  end

  def handle_in(
        "move_to_foundation_from_deck",
        _payload,
        %{topic: "game:" <> token} = socket
      ) do
    new_state = GameServer.move_to_foundation(token, :deck)
    {:reply, {:ok, new_state}, socket}
  end

  def handle_in("change", _params, %{topic: "game:" <> token} = socket) do
    new_state = GameServer.change(token)
    {:reply, {:ok, new_state}, socket}
  end

  def handle_in("cancel_move", _params, %{topic: "game:" <> token} = socket) do
    new_state = GameServer.cancel_move(token)
    {:reply, {:ok, new_state}, socket}
  end

  def handle_in(
        "move_from_deck",
        %{"to_column" => to_column},
        %{topic: "game:" <> token} = socket
      ) do
    case GameServer.move_from_deck(token, to_column) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, socket}

      {:error, _} ->
        {:reply, :error, socket}
    end
  end

  def handle_in(
        "move_from_deck",
        _params,
        %{topic: "game:" <> token} = socket
      ) do
    case GameServer.move_from_deck(token, []) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, socket}

      {:error, _} ->
        {:reply, :error, socket}
    end
  end
end
