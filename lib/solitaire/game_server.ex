defmodule Solitaire.Game.Sever do
  use GenServer

  alias Solitaire.Game

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @spec state(atom | pid | {atom, any} | {:via, atom, any}) :: any
  def state(pid) do
    GenServer.call(pid, :state)
  end

  @spec init(any) :: {:ok, Game.t(), {:continue, :give_cards}}
  def init(_) do
    {:ok, Game.shuffle(), {:continue, :give_cards}}
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

  def move_from_column(pid, from, to) do
    GenServer.call(pid, {:move_from_column, from, to})
  end

  def handle_continue(:give_cards, state) do
    Enum.each(0..6, fn el -> take_cards_to_col(self(), el) end)
    shuffle_cards_by_three(self())
    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:change, _from, state) do
    IO.inspect("empty!!!")

    {current, new_deck} = Game.change(state)

    new_state =
      Map.put(state, :deck, new_deck) |> Map.put(:current, current) |> put_deck_length(new_deck)

    {:reply, new_state, new_state}
  end

  def handle_call(:change, _from, %{deck: [h | t]} = state) do
    {current, new_deck} = Game.change(state)

    new_state =
      Map.put(state, :deck, new_deck)
      |> Map.put(:current, current)
      |> put_deck_length(new_deck)
      |> IO.inspect(label: "new state")

    {:reply, new_state, new_state}
  end

  defp put_deck_length(state, deck) do
    deck_length = Enum.find_index(deck, &(&1 == [])) || 7
    %{state | deck_length: deck_length}
  end

  def handle_call(
        {:move_from_deck, column},
        _from,
        state
      ) do
    # state |> IO.inspect(label: "state")

    result = Game.move_from_deck(state, column)

    new_state =
      Map.put(state, :cols, result.cols)
      |> Map.put(:deck, result.deck)
      |> Map.put(:current, result.current)

    # |> IO.inspect(label: "new state")

    {:reply, new_state, new_state}
  end

  def handle_call({:move_from_column, from, to}, _from, state) do
    {_, result} = Game.move_from_column(state, from, to)

    new_state =
      Map.put(state, :cols, result.cols)
      |> Map.put(:deck, result.deck)
      |> Map.put(:current, result.current)

    {:reply, new_state, new_state}
  end

  def handle_cast({:split_by, count}, %{deck: deck} = state) do
    [[current | _] | _] = splitted_deck = Game.split_deck_by(deck, count) ++ [[]]
    new_state = Map.put(state, :deck, splitted_deck) |> Map.put(:current, current)
    {:noreply, new_state}
  end

  def handle_cast({:set_col, col_num}, %{deck: deck, cols: cols} = state) do
    {cards, rest} = Game.take_card_from_deck(deck, col_num + 1)

    new_state =
      Map.merge(state, %{
        deck: rest,
        cols: List.insert_at(cols, col_num, %{cards: cards, unplayed: col_num})
      })

    {:noreply, new_state}
  end
end
