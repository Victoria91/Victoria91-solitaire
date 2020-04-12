defmodule Solitaire.Game.Autoplayer do
  alias Solitaire.Game

  def perform_autowin(
        %{
          foundation: %{"club" => "K", "diamond" => "K", "heart" => "K", "spade" => "K"}
        } = game
      ),
      do: game

  def perform_autowin(%{cols: cols} = game) do
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

    perform_autowin(new_game)
  end
end
