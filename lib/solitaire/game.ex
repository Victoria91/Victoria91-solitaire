defmodule Solitaire.Game do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def init(_) do
    {:ok, %{deck: Solitaire.shuffle(), cols: []}, {:continue, :give_cards}}
  end

  def take_cards_to_col(pid, col_num) do
    GenServer.cast(pid, {:set_col, col_num})
  end

  def handle_continue(:give_cards, %{deck: deck} = state) do
    Enum.each(0..6, fn el -> take_cards_to_col(self, el) end)
    {:noreply, state}
  end

  def handle_call(:state, _from, %{deck: deck} = state) do
    {:reply, state, state}
  end

  def handle_cast({:set_col, col_num}, %{deck: deck, cols: cols} = state) do
    {cards, rest} = take_card_from_deck(deck, col_num + 1) |> IO.inspect(label: "take result")

    new_state = Map.merge(state, %{deck: rest, cols: List.insert_at(cols, col_num, cards)})
    {:noreply, new_state}
  end

  defp take_card_from_deck(deck, count) do
    Enum.split(deck, count)
  end
end
