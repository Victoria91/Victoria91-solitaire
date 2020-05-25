defmodule Solitaire.Game.ServerTest do
  alias Solitaire.Game.Server, as: GameServer
  alias Solitaire.Game.MnesiaPersister

  use ExUnit.Case, async: false

  setup do
    {:ok,
     %{
       token: "token",
       state: %{cols: [], deck: [{:spade, 2}], deck_length: 1, foundation: %{A: 2}}
     }}
  end

  describe "#start_link" do
    @tag :skip

    test "when there is state in mnesia - loads it to server state", %{token: token, state: state} do
      MnesiaPersister.save(token, :klondike, state)
      {:ok, _pid} = GameServer.start_link(%{token: token, type: :klondike})
      assert state == Map.drop(GameServer.state(token), [:token, :type])
    end

    test "if no state in mnesia - loads new game", %{token: token} do
      {:ok, _pid} = GameServer.start_link(%{token: token})
      state = GameServer.state(token)
      assert state.cols != []
    end
  end

  describe "#stop" do
    @tag :skip

    test "clears saved state", %{token: token} do
      GameServer.start_link(%{token: token, type: :spider})
      GameServer.stop(token)

      assert MnesiaPersister.get_by_token_and_type(token, :spider) == nil
    end
  end

  describe "persisting data" do
    @tag :skip
    test "persists data", %{token: token} do
      GameServer.start_link(%{token: token, type: :klondike})
      GameServer.move_from_deck(token, 1)
      state = GameServer.state(token)

      persisted_state = MnesiaPersister.get_by_token_and_type(token, :klondike)

      assert state == persisted_state
    end
  end
end
