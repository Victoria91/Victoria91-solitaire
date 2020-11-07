defmodule Solitaire.Game.SpiderTest do
  alias Solitaire.Game.Spider

  use ExUnit.Case, async: true

  setup do
    game = Spider.load_game(2)
    {:ok, %{game: game}}
  end

  describe "#move_to_foundation" do
    test "1", %{game: %{cols: cols} = game} do
      new_cols =
        List.replace_at(cols, 0, %{
          cards: [
            {:spade, :A},
            {:spade, 2},
            {:spade, 3},
            {:spade, 4},
            {:spade, 5},
            {:spade, 6},
            {:spade, 7},
            {:spade, 8},
            {:spade, 9},
            {:spade, 10},
            {:spade, :J},
            {:spade, :D},
            {:spade, :K}
          ],
          unplayed: 0
        })

      game = %{game | cols: new_cols}

      %{foundation: foundation, cols: cols} = Spider.move_to_foundation(game, 0, [])
      assert %{spade: %{count: 1, from: ["column", 0]}} = foundation
      assert Enum.at(cols, 0) == %{cards: [], unplayed: 0}
    end

    test "2", %{game: %{cols: cols} = game} do
      new_cols =
        List.replace_at(cols, 0, %{
          cards: [
            {:spade, :A},
            {:spade, 2},
            {:spade, 3},
            {:spade, 5},
            {:spade, 4},
            {:spade, 6},
            {:spade, 7},
            {:spade, 8},
            {:spade, 9},
            {:spade, 10},
            {:spade, :J},
            {:spade, :D},
            {:spade, :K}
          ],
          unplayed: 0
        })

      game = %{game | cols: new_cols}

      %{foundation: foundation, cols: cols} = Spider.move_to_foundation(game, 0, [])
      assert %{spade: %{from: nil, prev: nil, rank: nil}} = foundation
      assert cols == new_cols
    end
  end
end
