defmodule Solitaire.Game.SpiderTest do
  alias Solitaire.Game.Spider

  use ExUnit.Case, async: true

  setup do
    game = Spider.load_game(2)
    {:ok, %{game: game}}
  end

  describe "#move_to_foundation" do
    test "when card come in ascending order - performs move to foundation", %{
      game: %{cols: cols} = game
    } do
      new_cols =
        cols
        |> List.replace_at(0, %{
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
            {:spade, :Q},
            {:spade, :K}
          ],
          unplayed: 0
        })
        |> List.replace_at(1, %{
          cards: [
            {:heart, :A},
            {:heart, 2},
            {:heart, 3},
            {:heart, 4},
            {:heart, 5},
            {:heart, 6},
            {:heart, 7},
            {:heart, 8},
            {:heart, 9},
            {:heart, 10},
            {:heart, :J},
            {:heart, :Q},
            {:heart, :K}
          ],
          unplayed: 0
        })

      game = %{game | cols: new_cols}

      new_game = Spider.move_to_foundation(game, 0, [])
      %{foundation: foundation, cols: cols} = Spider.move_to_foundation(new_game, 1, [])
      assert %{spade: %{count: 1, from: ["column", 0]}} = foundation
      assert %{heart: %{count: 1, from: ["column", 1]}} = foundation
      assert %{sorted: [:spade, :heart]} = foundation
      assert Enum.at(cols, 0) == %{cards: [], unplayed: 0}
    end

    test "when card come in wrong order - does not perform move to foundation", %{
      game: %{cols: cols} = game
    } do
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
            {:spade, :Q},
            {:spade, :K}
          ],
          unplayed: 0
        })

      game = %{game | cols: new_cols}

      %{foundation: foundation, cols: cols} = Spider.move_to_foundation(game, 0, [])
      assert %{spade: %{from: nil, prev: nil, rank: nil}} = foundation
      assert cols == new_cols
    end

    test "only one card - does not perfom move to foundation", %{
      game: %{cols: cols} = game
    } do
      new_cols =
        List.replace_at(cols, 0, %{
          cards: [
            {:spade, :A},
            {:spade, 2},
            {:spade, 3},
            {:spade, 5}
          ],
          unplayed: 0
        })

      game = %{game | cols: new_cols}

      %{foundation: foundation, cols: cols} = Spider.move_to_foundation(game, 0, [])
      assert %{spade: %{from: nil, prev: nil, rank: nil}} = foundation
      assert cols == new_cols
    end
  end

  test "updates moveable count", %{
    game: %{cols: cols} = game
  } do
    new_cols =
      cols
      |> List.replace_at(0, %{
        cards: [
          {:spade, 3},
          {:spade, 4},
          {:spade, :A}
        ],
        moveable: 2,
        unplayed: 0
      })
      |> List.replace_at(1, %{
        cards: [
          {:heart, 2}
        ],
        moveable: 1,
        unplayed: 0
      })

    game = %{game | cols: new_cols}

    {:ok, %{cols: [%{moveable: 1} | [%{moveable: 0} | _col]]}} =
      Spider.move_from_column(game, {1, 0}, 0)
  end
end
