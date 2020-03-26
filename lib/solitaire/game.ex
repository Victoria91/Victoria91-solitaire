defmodule Solitaire.Game do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def init(_) do
    {:ok, %{deck: Solitaire.shuffle(), cols: [], current: nil}, {:continue, :give_cards}}
  end

  def take_cards_to_col(pid, col_num) do
    GenServer.cast(pid, {:set_col, col_num})
  end

  def shuffle_cards_by_three(pid) do
    GenServer.cast(pid, {:split_by, 3})
  end

  def change(pid) do
    GenServer.call(pid, :change)
  end

  def move_from_deck(pid, column) do
    GenServer.call(pid, {:move_from_deck, column})
  end

  def handle_continue(:give_cards, state) do
    Enum.each(0..6, fn el -> take_cards_to_col(self, el) end)
    shuffle_cards_by_three(self)
    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:change, _from, %{deck: [h | [[] | t]]} = state) do
    IO.inspect("empty!!!")
    current = t |> List.first() |> List.first()
    new_state = Map.put(state, :deck, t ++ [h]) |> Map.put(:current, current)

    {:reply, new_state, new_state}
  end

  def handle_call(:change, _from, %{deck: [h | t]} = state) do
    h |> IO.inspect(label: "head")
    current = t |> List.first() |> List.first()

    new_state =
      Map.put(state, :deck, t ++ [h])
      |> Map.put(:current, current)
      |> IO.inspect(label: "new state")

    {:reply, new_state, new_state}
  end

  def handle_call(
        {:move_from_deck, column},
        _from,
        %{current: current, deck: [[current | [next | _] = rest] | rest_deck], cols: cols} = state
      ) do
    state |> IO.inspect(label: "state")
    deck = [rest | rest_deck]

    %{cards: cards, unplayed: unplayed} = Enum.at(cols, column)

    cards = cards ++ [current]

    cols = List.replace_at(cols, column, %{cards: cards, unplayed: unplayed})

    new_state =
      Map.put(state, :cols, cols)
      |> Map.put(:deck, deck)
      |> Map.put(:current, next)
      |> IO.inspect(label: "new state")

    {:reply, new_state, new_state}
  end

  def handle_cast({:split_by, count}, %{deck: deck} = state) do
    [[current | _] | _] = splitted_deck = Enum.chunk_every(deck, count) ++ [[]]
    new_state = Map.put(state, :deck, splitted_deck) |> Map.put(:current, current)
    {:noreply, new_state}
  end

  def handle_cast({:set_col, col_num}, %{deck: deck, cols: cols} = state) do
    {cards, rest} = take_card_from_deck(deck, col_num + 1)

    new_state =
      Map.merge(state, %{
        deck: rest,
        cols: List.insert_at(cols, col_num, %{cards: cards, unplayed: col_num})
      })

    {:noreply, new_state}
  end

  defp take_card_from_deck(deck, count) do
    Enum.split(deck, count)
  end
end
