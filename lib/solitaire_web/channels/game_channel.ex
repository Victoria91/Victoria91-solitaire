defmodule SolitaireWeb.GameChannel do
  use SolitaireWeb, :channel

  alias Solitaire.Game.Server, as: GameServer

  def join(_topic, _params, socket) do
    token = 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

    GameServer.start_link(%{token: token, type: :klondike})

    state = GameServer.state(token)

    Phoenix.PubSub.subscribe(Solitaire.PubSub, "game:#{token}")

    {:ok, fetch_game_state(state), assign(socket, :token, token)}
  end

  def handle_info({:tick, game}, socket) do
    broadcast!(socket, "update_game", fetch_game_state(game))

    {:noreply, socket}
  end

  def fetch_game_state(%{cols: cols, deck: deck, deck_length: deck_length}) do
    %{
      columns:
        Enum.map(cols, fn %{cards: cards} = map ->
          %{map | cards: convert_keyword_to_list(cards)}
        end),
      deck_length: deck_length,
      deck: deck |> Enum.map(&convert_keyword_to_list/1) |> List.first()
    }
  end

  defp convert_keyword_to_list(kw) do
    Enum.map(kw, fn
      [] -> []
      {k, v} -> [k, v]
    end)
  end

  def handle_in(
        "move_from_column",
        %{
          "from_card_index" => card_index,
          "from_column" => from_column,
          "to_column" => to_column
        },
        %{assigns: %{token: token}} = socket
      ) do
    case GameServer.move_from_column(token, {from_column, card_index}, to_column) do
      {:ok, new_state} ->
        {:reply, {:ok, fetch_game_state(new_state)}, socket}

      {:error, _} ->
        {:reply, :error, socket}
    end
  end

  def handle_in("change", _params, %{assigns: %{token: token}} = socket) do
    new_state = GameServer.change(token)
    {:reply, {:ok, fetch_game_state(new_state)}, socket}
  end

  def handle_in(
        "move_from_deck",
        %{"to_column" => to_column},
        %{assigns: %{token: token}} = socket
      ) do
    case GameServer.move_from_deck(token, to_column) do
      {:ok, new_state} ->
        {:reply, {:ok, fetch_game_state(new_state)}, socket}

      {:error, _} ->
        {:reply, :error, socket}
    end
  end
end
