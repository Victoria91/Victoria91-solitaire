defmodule Solitaire.GameTest do
  alias Solitaire.Game
  alias Solitaire.Game.Sever, as: GameServer
  use ExUnit.Case

  describe "#change" do
    setup do
      {:ok, pid} = GameServer.start_link([])
      {:ok, %{pid: pid}}
    end

    test "changes - next cards move to top, current cards - to the end of the queue", %{pid: pid} do
      #       deck = [
      #         [{"diamond", "5"}, {"club", "6"}, {"diamond", "A"}],
      #         [{"spade", "3"}, {"diamond", "K"}, {"club", "A"}],
      #         []
      #       ]

      #       {_, result_deck} = Game.change(%{deck: deck}) |> IO.inspect()
      # assert result_deck
      %{deck: [h | rest] = deck} = game = GameServer.state(pid)
      rest_deck = res = Game.change(game)
      assert rest ++ [h] == res
      assert length(rest_deck) == length(deck)
    end

    test "if riched end of the deck - splits deck again by three, changes deck" do
      deck = [
        [{"club", "5"}, {"club", "K"}, {"spade", "K"}],
        [],
        [{"heart", "A"}, {"club", "2"}],
        [{"heart", "8"}, {"club", "10"}, {"club", "6"}]
      ]

      new_deck = Game.change(%{deck: deck})
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

      new_cols =
        cols
        |> List.replace_at(3, %{cards: [{"heart", "K"}], unplayed: 0})
        |> List.replace_at(4, %{cards: [{"spade", "K"}], unplayed: 0})
        |> List.replace_at(5, %{cards: [{"diamond", "10"}], unplayed: 0})
        |> List.replace_at(0, %{cards: [], unplayed: 0})

      game = %{game | cols: new_cols}
      Game.move_from_column(game, 3, 0)
    end
  end

  describe "#move_from_deck/2" do
    setup do
      {:ok, pid} = GameServer.start_link([])
      {:ok, %{pid: pid}}
    end

    test "1", %{pid: pid} do
      %{cols: cols} = game = GameServer.state(pid)

      initial_deck = [
        [{"heart", "4"}],
        [{"spade", "4"}, {"club", "8"}, {"club", "A"}],
        [{"spade", "3"}, {"club", "6"}, {"diamond", "10"}],
        []
      ]

      to_column = %{cards: [{"spade", "5"}], unplayed: 0}
      cols = List.replace_at(cols, 2, to_column)

      game =
        game
        |> Map.put(:deck, initial_deck)
        |> Map.put(:cols, cols)

      %{deck: result_deck, cols: result_cols} = Game.move_from_deck(game, 2)
      assert result_deck == Enum.slice(initial_deck, 1..-1)
      %{cards: result_cards} = Enum.at(result_cols, 2)
      assert result_cards == [{"heart", "4"}, {"spade", "5"}]
    end

    @tag :skip
    test "2", %{pid: pid} do
      %{cols: cols} = game = GameServer.state(pid)

      initial_deck = [
        [{"heart", "4"}],
        [],
        [{"diamond", "2"}, {"heart", "D"}, {"heart", "3"}]
      ]

      to_column = %{cards: [{"spade", "5"}], unplayed: 0}
      cols = List.replace_at(cols, 2, to_column)

      game =
        game
        |> Map.put(:deck, initial_deck)
        |> Map.put(:cols, cols)

      %{deck: result_deck, cols: result_cols} = Game.move_from_deck(game, 2)

      assert result_deck == Enum.slice(initial_deck, 2..-1) ++ [[]]
      %{cards: result_cards} = Enum.at(result_cols, 2)
      assert result_cards == [{"heart", "4"}, {"spade", "5"}]
    end

    test "3", %{pid: pid} do
      deck = [
        [{"diamond", "5"}, {"club", "6"}, {"diamond", "A"}],
        [{"spade", "3"}, {"diamond", "K"}, {"club", "A"}],
        []
      ]

      %{cols: cols} = game = GameServer.state(pid)

      new_cols =
        cols
        |> List.replace_at(3, %{cards: [{"club", "6"}], unplayed: 0})

      game =
        game
        |> Map.put(:deck, deck)
        |> Map.put(:cols, new_cols)

      %{deck: result_deck} = Game.move_from_deck(game, 3)

      assert result_deck == [
               [{"club", "6"}, {"diamond", "A"}],
               [{"spade", "3"}, {"diamond", "K"}, {"club", "A"}],
               []
             ]
    end

    test "4" do
      game = %Solitaire.Game{
        cols: [
          %{cards: [{"club", "D"}, {"diamond", "K"}], unplayed: 0},
          %{cards: [{"diamond", "6"}], unplayed: 0},
          %{
            cards: [
              {"diamond", "5"},
              {"club", "6"},
              {"heart", "7"},
              {"diamond", "10"}
            ],
            unplayed: 1
          },
          %{
            cards: [{"spade", "2"}, {"heart", "10"}, {"club", "10"}, {"club", "J"}],
            unplayed: 3
          },
          %{
            cards: [
              {"spade", "A"},
              {"diamond", "2"},
              {"club", "3"},
              {"spade", "8"},
              {"spade", "10"},
              {"diamond", "4"},
              {"spade", "4"}
            ],
            unplayed: 4
          },
          %{
            cards: [
              {"spade", "J"},
              {"diamond", "D"},
              {"club", "2"},
              {"diamond", "A"},
              {"spade", "5"},
              {"diamond", "J"}
            ],
            unplayed: 5
          },
          %{
            cards: [
              {"heart", "9"},
              {"heart", "6"},
              {"spade", "3"},
              {"diamond", "7"},
              {"diamond", "3"},
              {"spade", "D"}
            ],
            unplayed: 5
          }
        ],
        deck: [
          [{"heart", "J"}, {"heart", "D"}, {"club", "8"}],
          [],
          [{"club", "9"}, {"diamond", "9"}, {"club", "5"}]
        ],
        deck_length: 1
      }

      Game.move_from_deck(game, 0)
    end
  end

  describe "#move_to_foundation/2 (game, :deck)" do
    test "when foundation is nil - A is available for move" do
      game = %{deck: [[{"spade", "A"}], []], foundation: %{"spade" => nil}}

      Game.move_to_foundation(game, :deck)

      assert %{deck: [[], []], foundation: %{"spade" => "A"}} ==
               Game.move_to_foundation(game, :deck)
    end

    test "with non-empty foundation - next rank is available" do
      game = %{deck: [[{"spade", "2"}], []], foundation: %{"spade" => "A"}}

      assert %{deck: [[], []], foundation: %{"spade" => "2"}} ==
               Game.move_to_foundation(game, :deck)
    end
  end

  describe "#move_to_foundation/2 (game, column)" do
    test "when foundation is nil - A is available for move" do
      game = %{cols: [%{cards: [{"spade", "A"}], unplayed: 0}], foundation: %{"spade" => nil}}

      Game.move_to_foundation(game, 0)

      assert %{cols: [%{cards: [], unplayed: 0}], foundation: %{"spade" => "A"}} ==
               Game.move_to_foundation(game, 0)
    end

    test "with non-empty foundation - next rank is available" do
      game = %{cols: [%{cards: [{"spade", "2"}], unplayed: 0}], foundation: %{"spade" => "A"}}

      assert %{cols: [%{cards: [], unplayed: 0}], foundation: %{"spade" => "2"}} ==
               Game.move_to_foundation(game, 0)
    end

    test "unplayed handling" do
      game = %{
        cols: [%{cards: [{"spade", "2"}, {"heart", "3"}, {"king", "4"}], unplayed: 1}],
        foundation: %{"spade" => "A"}
      }

      assert %{
               cols: [%{cards: [{"heart", "3"}, {"king", "4"}], unplayed: 1}],
               foundation: %{"spade" => "2"}
             } ==
               Game.move_to_foundation(game, 0)
    end
  end
end
