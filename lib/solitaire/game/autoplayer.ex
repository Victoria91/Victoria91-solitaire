defmodule Solitaire.Game.Autoplayer do
  alias Solitaire.Game
  alias Solitaire.Game.Sever, as: GameServer

  def start do
    {:ok, pid} = GameServer.start_link([])

    Task.async(fn ->
      state = GameServer.state(pid)

      perform_autowin(state, pid)
    end)
  end

  def perform_autowin(
        %{
          foundation: %{"club" => "K", "diamond" => "K", "heart" => "K", "spade" => "K"}
        } = game,
        pid,
        _
      ),
      do: update_game_server_state(pid, game)

  def perform_autowin(game, pid, 0), do: update_game_server_state(pid, game)

  def perform_autowin(%{cols: cols} = game, pid, count \\ 50) do
    new_game = Game.move_to_foundation(game, :deck)

    new_game =
      cols
      |> Enum.with_index()
      |> Enum.reduce(game, fn {_col, index}, game ->
        game =
          Game.move_to_foundation(game, :deck)
          |> Game.move_from_deck(index)
          |> Game.move_to_foundation(index)

        Phoenix.PubSub.broadcast(Solitaire.PubSub, "game", {:tick, game})
        :timer.sleep(40)
        game
      end)

    new_game = Map.put(new_game, :deck, Game.change(new_game))
    Phoenix.PubSub.broadcast(Solitaire.PubSub, "game", {:tick, new_game})

    update_game_server_state(pid, game)

    perform_autowin(new_game, pid, count - 1)
  end

  defp update_game_server_state(pid, state) do
    GameServer.state(pid, state)
  end
end
