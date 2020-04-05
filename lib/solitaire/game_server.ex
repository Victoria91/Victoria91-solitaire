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
    new_deck = Game.change(state) |> IO.inspect(label: "new_deck")
    state |> IO.inspect(label: "STATE ON CHANGE")

    new_state = Map.put(state, :deck, new_deck) |> put_deck_length

    check_length(state)
    {:reply, new_state, new_state}
  end

  def handle_call(
        {:move_from_deck, column},
        _from,
        state
      ) do
    state |> IO.inspect(label: "STATE ON move_from_deck")

    result = Game.move_from_deck(state, column)

    new_state =
      Map.put(state, :cols, result.cols)
      |> Map.put(:deck, result.deck)

    check_length(new_state)

    {:reply, new_state, new_state}
  end

  def handle_call({:move_from_column, from, to}, _from, state) do
    state |> IO.inspect(label: "STATE ON move_from_column")
    {_, result} = Game.move_from_column(state, from, to)

    new_state =
      Map.put(state, :cols, result.cols)
      |> Map.put(:deck, result.deck)

    check_length(new_state)

    {:reply, new_state, new_state}
  end

  def handle_cast({:split_by, count}, %{deck: deck} = state) do
    splitted_deck = Game.split_deck_by(deck, count) ++ [[]]
    new_state = Map.put(state, :deck, splitted_deck)

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

  defp put_deck_length(%{deck: deck} = state) do
    deck_length = Enum.find_index(deck, &(&1 == [])) || 7
    %{state | deck_length: deck_length}
  end

  def check_length(%{deck: deck, cols: cols}) do
    cols_len =
      cols
      |> Enum.map(& &1[:cards])
      |> Enum.map(&length/1)
      |> Enum.reduce(&(&1 + &2))

    deck_len =
      deck
      |> Enum.map(&length/1)
      |> Enum.reduce(&(&1 + &2))

    if cols_len + deck_len != 52 |> IO.inspect(label: "length") do
      raise "AOAOAOOO"
    end
  end
end
