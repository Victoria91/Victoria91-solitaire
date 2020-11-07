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

  def play(game, pid, count \\ 50)

  @spec play(Solitaire.Games.t(), any, non_neg_integer()) :: Solitaire.Games.t()
  @doc "Автобой"
  def play(
        %{
          foundation: %{"club" => "K", "diamond" => "K", "heart" => "K", "spade" => "K"}
        } = game,
        _pid,
        _count
      ),
      do: game

  def play(game, _pid, 0), do: game

  def play(%{cols: cols}, pid, count) do
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
    sleep_unless_test(200)
    GameServer.move_to_foundation(pid, :deck, auto: true)

    new_game =
      %{foundation: new_foundation} =
      cols
      |> Enum.with_index()
      |> Enum.reduce(game, fn {_col, index}, old_game ->
        game = GameServer.move_to_foundation(pid, index, auto: true)

        if old_game != game do
          broadcast_to_game_topic(pid, game)
        end

        sleep_unless_test(40)
        game
      end)

    if new_foundation != foundation do
      perform_automove_to_foundation(new_game, pid)
    end
  end

  defp sleep_unless_test(timeout) do
    if Mix.env() != :test do
      :timer.sleep(timeout)
    end
  end

  defp broadcast_to_game_topic(pid, game) do
    Phoenix.PubSub.broadcast(Solitaire.PubSub, "game:#{pid}", {:tick, game})
  end
end
