defmodule Solitaire do
  @moduledoc """
  Solitaire keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @suits ~w(spade diamond heart club)
  @ranks ~w(2 3 4 5 6 7 8 9 10 J D K A)

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
end
