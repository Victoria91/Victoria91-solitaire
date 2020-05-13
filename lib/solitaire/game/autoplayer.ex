defmodule Solitaire.Game.Autoplayer do
  alias Solitaire.Game.Server, as: GameServer

  def start(token, opts \\ []) do
    async = Keyword.get(opts, :async, false)
    wait = Keyword.get(opts, :async, false)

    fun = fn ->
      GameServer.start_link(token)
      if wait, do: :timer.sleep(:rand.uniform(1_000_000))
      state = GameServer.state(token)
      play(state, token)
    end

    if async, do: Task.async(fun), else: fun.()
  end

  @spec play(Solitaire.Games.t(), any, non_neg_integer()) :: Solitaire.Games.t()
  @doc "Автобой"
  def play(
        %{
          foundation: %{"club" => "K", "diamond" => "K", "heart" => "K", "spade" => "K"}
        } = game,
        _pid,
        _
      ),
      do: game

  def play(game, _pid, 0), do: game

  def play(%{cols: cols}, pid, count \\ 50) do
    GameServer.move_to_foundation(pid, :deck)

    cols
    |> Enum.with_index()
    |> Enum.each(fn {_col, index} ->
      GameServer.move_to_foundation(pid, :deck)

      GameServer.move_from_deck(pid, index)

      GameServer.move_to_foundation(pid, index)

      game = GameServer.state(pid)
      broadcast_to_game_topic(pid, game)
    end)

    new_game = GameServer.change(pid)

    broadcast_to_game_topic(pid, new_game)

    play(new_game, pid, count - 1)
  end

  @doc """
    Автоматически раскладывает оставшиеся карты на столе (вызывается когда колода пуста
    и все карты на столе открыты). Бродкастит сообщение для liveview для обновления стола
    на фронте
  """

  def perform_automove_to_foundation(
        %{
          foundation: %{"club" => "K", "diamond" => "K", "heart" => "K", "spade" => "K"}
        } = game,
        _pid
      ),
      do: game

  def perform_automove_to_foundation(%{cols: cols, foundation: foundation} = game, pid) do
    :timer.sleep(200)
    GameServer.move_to_foundation(pid, :deck)

    new_game =
      %{foundation: new_foundation} =
      cols
      |> Enum.with_index()
      |> Enum.reduce(game, fn {_col, index}, _game ->
        game = GameServer.move_to_foundation(pid, index)
        broadcast_to_game_topic(pid, game)
        :timer.sleep(40)
        game
      end)

    if new_foundation != foundation do
      perform_automove_to_foundation(new_game, pid)
    end
  end

  defp broadcast_to_game_topic(pid, game) do
    Phoenix.PubSub.broadcast(Solitaire.PubSub, "game:#{pid}", {:tick, game})
  end
end
