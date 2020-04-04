defmodule Solitaire.GameTest do
  alias Solitaire.Game
  alias Solitaire.Game.Sever, as: GameServer
  use ExUnit.Case

  describe "#change" do
    setup do
      {:ok, pid} = GameServer.start_link([])
      {:ok, %{pid: pid}}
      # {:ok, }
    end

    test "changes - next cards move to top, current cards - to the end of the queue", %{pid: pid} do
      %{deck: [h | [ht | _tt] = rest] = deck} = game = GameServer.state(pid) |> IO.inspect()
      {_current, rest_deck} = res = Game.change(game) |> IO.inspect()
      assert {hd(ht), rest ++ [h]} == res
      assert length(rest_deck) == length(deck)
    end

    test "if riched end of the deck - splits deck again by three, changes deck" do
      deck = [
        [{"club", "5"}, {"club", "K"}, {"spade", "K"}],
        [],
        [{"heart", "A"}, {"club", "2"}],
        [{"heart", "8"}, {"club", "10"}, {"club", "6"}]
      ]

      {current, new_deck} = Game.change(%{deck: deck})
      assert current == {"heart", "A"}
      deck_chunk_length = Enum.map(new_deck, &length/1)
      assert deck_chunk_length == [3, 3, 2, 0]
    end
  end

  describe "#move_from_column/3" do
    setup do
      {:ok, pid} = GameServer.start_link([])
      {:ok, %{pid: pid}}
      # {:ok, }
    end

    test "when to column black - only King can be moved", %{pid: pid} do
      %{cols: cols} = game = GameServer.state(pid)

      # cols |> IO.inspexct()

      new_cols =
        cols
        |> List.replace_at(3, %{cards: [{"heart", "K"}], unplayed: 0})
        |> List.replace_at(4, %{cards: [{"spade", "K"}], unplayed: 0})
        |> List.replace_at(5, %{cards: [{"diamond", "10"}], unplayed: 0})
        |> List.replace_at(0, %{cards: [], unplayed: 0})
        |> IO.inspect()

      game = %{game | cols: new_cols}
      Game.move_from_column(game, 3, 0) |> IO.inspect()
    end
  end
end
