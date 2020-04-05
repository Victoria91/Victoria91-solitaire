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
      %{deck: [h | rest] = deck} = game = GameServer.state(pid) |> IO.inspect()
      rest_deck = res = Game.change(game) |> IO.inspect(label: "res")
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
        |> IO.inspect()

      game = %{game | cols: new_cols}
      Game.move_from_column(game, 3, 0) |> IO.inspect()
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

      %{deck: result_deck, cols: result_cols} =
        Game.move_from_deck(game, 2) |> IO.inspect(label: "res")

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
          # [{"heart", "4"}, {"spade", "6"}, {"heart", "3"}],
          # [{"spade", "K"}, {"heart", "8"}, {"spade", "7"}],
          # [{"club", "7"}, {"heart", "A"}],
          # [{"spade", "9"}, {"diamond", "8"}, {"heart", "2"}],
          # [{"club", "K"}, {"club", "4"}],
          # [{"heart", "5"}, {"heart", "K"}, {"club", "A"}]
        ],
        deck_length: 1
      }

      Game.move_from_deck(game, 0) |> IO.inspect()
      # GameServer.check_length(game) |> IO.inspect()
    end
  end
end
