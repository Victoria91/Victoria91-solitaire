defmodule SolitaireWeb.GameChannel do
  use SolitaireWeb, :channel

  alias Solitaire.Game.Server, as: GameServer

  def join(_topic, _params, socket) do
    token = 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64()

    GameServer.start_link(%{token: token, type: :klondike})

    state = GameServer.state(token)

    Phoenix.PubSub.subscribe(Solitaire.PubSub, "game:#{token}")

    {:ok, %{data: fetch_cards(state)}, assign(socket, :token, token)}
  end

  def handle_info({:tick, game}, socket) do
    broadcast!(socket, "update_game", %{data: fetch_cards(game)})

    {:noreply, socket}
  end

  def fetch_cards(%{cols: cols}) do
    Enum.map(cols, fn %{cards: cards} = map -> %{map | cards: convert_keyword_to_list(cards)} end)
  end

  defp convert_keyword_to_list(kw) do
    Enum.map(kw, fn {k, v} -> [k, v] end)
  end

  def handle_in(
        "move_to_column",
        %{
          "from_card_index" => card_index,
          "from_column" => from_column,
          "to_column" => to_column
        },
        %{assigns: %{token: token}} = socket
      ) do
    case GameServer.move_from_column(token, {from_column, card_index}, to_column) do
      {:ok, new_state} ->
        {:reply, {:ok, %{data: fetch_cards(new_state)}}, socket}

      {:error, _} ->
        {:reply, :error, socket}
    end
  end
end
