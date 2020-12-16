defmodule Solitaire.Game.ServerTest do
  alias Solitaire.Game.Server, as: GameServer

  # alias Solitaire.Game.MnesiaPersister

  use ExUnit.Case, async: true

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
      # MnesiaPersister.save(token, :klondike, state)
      assert state == Map.drop(GameServer.state(token), [:token, :type])
      {:ok, _pid} = GameServer.start_link(%{token: token, type: :klondike})
    end

    test "when A and 2 available for foundation - puts them to foundation", %{token: token} do
      {:ok, _pid} =
        GameServer.start_link(%{
          suit_count: 1,
          game_state: %{
            cols: [
              %{cards: [{:spade, :A}], unplayed: 0},
              %{cards: [{:spade, 2}], unplayed: 0},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []}
            ],
            deck: [[]],
            deck_length: 1,
            foundation: %{
              spade: %{rank: nil, from: nil, prev: nil},
              diamond: %{rank: nil, from: nil, prev: nil},
              heart: %{rank: nil, from: nil, prev: nil},
              club: %{rank: nil, from: nil, prev: nil}
            }
          },
          type: :klondike,
          token: token
        })

      :timer.sleep(10)
      state = GameServer.state(token)
      assert state.cols != []

      assert state.foundation == %{
               club: %{from: nil, prev: nil, rank: nil},
               diamond: %{from: nil, prev: nil, rank: nil},
               heart: %{from: nil, prev: nil, rank: nil},
               spade: %{from: ["column", 1], prev: :A, rank: 2}
             }
    end

    test "when A and 3 available for foundation and other suits less then 2 - does not pefrom push to foundation",
         %{token: token} do
      {:ok, _pid} =
        GameServer.start_link(%{
          suit_count: 1,
          game_state: %{
            cols: [
              %{cards: [{:spade, 3}], unplayed: 0},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []}
            ],
            deck: [[]],
            deck_length: 1,
            foundation: %{
              spade: %{rank: 2, from: nil, prev: nil},
              diamond: %{rank: nil, from: nil, prev: nil},
              heart: %{rank: nil, from: nil, prev: nil},
              club: %{rank: nil, from: nil, prev: nil}
            }
          },
          type: :klondike,
          token: token
        })

      state = GameServer.state(token)
      assert state.cols != []

      assert state.foundation == %{
               club: %{from: nil, prev: nil, rank: nil},
               diamond: %{from: nil, prev: nil, rank: nil},
               heart: %{from: nil, prev: nil, rank: nil},
               spade: %{from: nil, rank: 2, prev: nil}
             }
    end

    test "when A and 3 available for foundation and all other color suits not less then 2 - pefrom push to foundation",
         %{token: token} do
      {:ok, _pid} =
        GameServer.start_link(%{
          suit_count: 1,
          game_state: %{
            cols: [
              %{cards: [{:spade, 3}], unplayed: 0},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []}
            ],
            deck: [[]],
            deck_length: 1,
            foundation: %{
              spade: %{from: ["column", 0], rank: 2},
              diamond: %{rank: 2, from: nil, prev: nil},
              heart: %{rank: 2, from: nil, prev: nil},
              club: %{rank: nil, from: nil, prev: nil}
            }
          },
          type: :klondike,
          token: token
        })

      :timer.sleep(10)
      state = GameServer.state(token)
      assert state.cols != []

      assert state.foundation == %{
               club: %{from: nil, prev: nil, rank: nil},
               diamond: %{from: nil, prev: nil, rank: 2},
               heart: %{from: nil, prev: nil, rank: 2},
               spade: %{from: ["column", 0], rank: 3, prev: 2}
             }
    end

    test "when 3 available for foundation and all other color suits not less then 2 - pefrom push to foundation",
         %{token: token} do
      {:ok, _pid} =
        GameServer.start_link(%{
          suit_count: 1,
          game_state: %{
            cols: [
              %{cards: [{:spade, 3}], unplayed: 0},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []}
            ],
            deck: [[]],
            deck_length: 1,
            foundation: %{
              spade: %{from: ["column", 0], rank: 2},
              diamond: %{rank: :A, from: nil, prev: nil},
              heart: %{rank: 2, from: nil, prev: nil},
              club: %{rank: nil, from: nil, prev: nil}
            }
          },
          type: :klondike,
          token: token
        })

      state = GameServer.state(token)
      assert state.cols != []

      assert state.foundation == %{
               club: %{from: nil, prev: nil, rank: nil},
               diamond: %{rank: :A, from: nil, prev: nil},
               heart: %{from: nil, prev: nil, rank: 2},
               spade: %{from: ["column", 0], rank: 2}
             }
    end

    test "when one card available and other not - does not pefrom push to foundation",
         %{token: token} do
      {:ok, _pid} =
        GameServer.start_link(%{
          suit_count: 1,
          game_state: %{
            cols: [
              %{cards: [{:spade, 3}], unplayed: 0},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []}
            ],
            deck: [[]],
            deck_length: 1,
            foundation: %{
              spade: %{from: ["column", 0], rank: 2},
              diamond: %{rank: 2, from: nil, prev: nil},
              heart: %{rank: nil, from: nil, prev: nil},
              club: %{rank: nil, from: nil, prev: nil}
            }
          },
          type: :klondike,
          token: token
        })

      state = GameServer.state(token)
      assert state.cols != []

      assert state.foundation == %{
               club: %{from: nil, prev: nil, rank: nil},
               diamond: %{from: nil, prev: nil, rank: 2},
               heart: %{from: nil, prev: nil, rank: nil},
               spade: %{from: ["column", 0], rank: 2}
             }
    end

    test "when A and 3 available for foundation from deck and all other color suits not less then 2 - pefrom push to foundation",
         %{token: token} do
      {:ok, _pid} =
        GameServer.start_link(%{
          suit_count: 1,
          game_state: %{
            cols: [
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []}
            ],
            deck: [[{:diamond, 3}], []],
            deck_length: 1,
            foundation: %{
              diamond: %{from: ["column", 0], rank: 2},
              spade: %{rank: 2, from: nil, prev: nil},
              club: %{rank: 2, from: nil, prev: nil},
              heart: %{rank: nil, from: nil, prev: nil}
            }
          },
          type: :klondike,
          token: token
        })

      :timer.sleep(10)
      state = GameServer.state(token)
      assert state.cols != []

      assert state.foundation == %{
               club: %{from: nil, prev: nil, rank: 2},
               diamond: %{from: ["deck"], prev: 2, rank: 3},
               heart: %{from: nil, prev: nil, rank: nil},
               spade: %{from: nil, prev: nil, rank: 2}
             }
    end
  end

  describe "cancel_move" do
    test "returns previous state", %{token: token} do
      {:ok, _pid} =
        GameServer.start_link(%{
          suit_count: 1,
          token: token,
          type: :klondike,
          game_state: %{
            deck_length: 0,
            foundation: %{},
            deck: [[spade: 7, spade: 4, spade: 2], [spade: 8, heart: 5, spade: 6]],
            cols: [
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []}
            ]
          }
        })

      state = GameServer.state(token)

      GameServer.change(token)

      GameServer.cancel_move(token)

      new_state = GameServer.state(token)

      assert state == new_state
    end

    test "not rollbacks state after win", %{token: token} do
      {:ok, _pid} =
        GameServer.start_link(%{
          suit_count: 1,
          token: token,
          type: :klondike,
          game_state: %{
            deck_length: 0,
            foundation: %{
              club: %{rank: :Q},
              diamond: %{rank: :K},
              heart: %{rank: :K},
              spade: %{rank: :K}
            },
            deck: [[club: :K], []],
            cols: [
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []},
              %{cards: []}
            ]
          }
        })

      assert %{
               club: %{rank: :K},
               diamond: %{rank: :K},
               heart: %{rank: :K},
               spade: %{rank: :K}
             } = GameServer.move_to_foundation(token, :deck).foundation

      assert %{
               club: %{rank: :K},
               diamond: %{rank: :K},
               heart: %{rank: :K},
               spade: %{rank: :K}
             } = GameServer.cancel_move(token).foundation
    end
  end

  describe "#stop" do
    @tag :skip

    test "clears saved state", %{token: token} do
      GameServer.start_link(%{token: token, type: :spider})
      GameServer.stop(token)

      # assert MnesiaPersister.get_by_token_and_type(token, :spider) == nil
    end
  end

  describe "persisting data" do
    @tag :skip
    test "persists data", %{token: token} do
      GameServer.start_link(%{token: token, type: :klondike})
      GameServer.move_from_deck(token, 1)
      GameServer.state(token)

      # persisted_state = MnesiaPersister.get_by_token_and_type(token, :klondike)

      # assert state == persisted_state
    end
  end
end
