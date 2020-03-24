defmodule Solitaire do
  @moduledoc """
  Solitaire keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @suits ~w(spade diamond heart club)
  @ranks ~w(1 2 3 4 5 6 7 8 9 10 J D K A)

  def deck do
    for s <- @suits do
      for r <- @ranks do
        {s, r}
      end
    end
    |> List.flatten()
  end

  def shuffle do
    deck
    |> Enum.shuffle()
  end

  def load_down do
    shuffle = shuffle()

    Enum.map(1..7, fn el ->
      take_from_shuffle(shuffle, el)
    end)
  end

  # def take_from_shuffle(shuffle, 0),
  def take_from_shuffle([card | rest] = shuffle, count) do
    Enum.slice(shuffle, (count - 1)..(count * 2 - 1))
    # while count > 0 do
    # {card, rest} = take_from_shuffle(rest, count - 1)
    # end
  end

  # 1 - 0..0  i
  # 2 - 1..2
  # 3 - 3..5
  # 4 - 6..9 i*2
  # 5 - 10..14 i*2
end
