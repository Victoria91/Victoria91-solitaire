defmodule Solitaire.Game.Sever do
  use GenServer

  alias Solitaire.{Game, Statix}

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    # Statix.increment("games")
    GenServer.start_link(__MODULE__, [])
  end

  @spec state(atom | pid | {atom, any} | {:via, atom, any}) :: any
  def state(pid) do
    measure("get_state", fn ->
      GenServer.call(pid, :state)
    end)
  end

  def state(pid, state) do
    measure("set state", fn ->
      GenServer.cast(pid, {:state, state})
    end)
  end

  @spec init(any) :: {:ok, Game.t(), {:continue, :give_cards}}
  def init(_) do
    {:ok, Game.shuffle(), {:continue, :give_cards}}
    # {:ok, %Game{}}
  end

  def take_cards_to_col(pid, col_num) do
    GenServer.cast(pid, {:set_col, col_num})
  end

  def shuffle_cards_by_three(pid) do
    GenServer.cast(pid, {:split_by, 3})
  end

  def move_to_foundation(pid, attr) do
    measure("move_to_foundation", fn ->
      GenServer.call(pid, {:move_to_foundation, attr})
    end)
  end

  defp measure(label, fun) do
    if Application.get_env(:statsd_logger, :enable) do
      Statix.measure(label, fun)
    else
      fun.()
    end
  end

  def change(pid) do
    measure("chanfe", fn ->
      GenServer.call(pid, :change)
    end)
  end

  def move_from_deck(pid, column) do
    measure("move_from_deck", fn ->
      GenServer.call(pid, {:move_from_deck, column})
    end)
  end

  def move_from_column(pid, from, to) do
    GenServer.call(pid, {:move_from_column, from, to})
  end

  def move_from_foundation(pid, suit, column) do
    measure("move_from_foundation", fn ->
      GenServer.call(pid, {:move_from_foundation, suit, column})
    end)
  end

  def handle_continue(:give_cards, _state) do
    state = Game.load_game()
    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:move_from_foundation, suit, column}, _from, state) do
    result = Game.move_from_foundation(state, suit, column)

    new_state =
      state
      |> update_game_state(result)
      |> put_deck_length

    {:reply, new_state, new_state}
  end

  def handle_call({:move_to_foundation, attr}, _from, state) do
    result = Game.move_to_foundation(state, attr)

    new_state = update_game_state(state, result)

    check_for_autowin(new_state)

    {:reply, new_state, new_state}
  end

  def handle_call(:change, _from, state) do
    result = Map.put(state, :deck, Game.change(state))
    new_state = state |> update_game_state(result) |> put_deck_length

    check_for_autowin(state)
    {:reply, new_state, new_state}
  end

  def handle_call(
        {:move_from_deck, column},
        _from,
        state
      ) do
    result = Game.move_from_deck(state, column)

    new_state = update_game_state(state, result)

    check_for_autowin(new_state)

    {:reply, new_state, new_state}
  end

  def handle_call({:move_from_column, from, to}, _from, state) do
    {_, result} = Game.move_from_column(state, from, to)

    new_state = update_game_state(state, result)

    check_for_autowin(new_state)

    {:reply, new_state, new_state}
  end

  def handle_cast({:state, new_state}, _) do
    {:noreply, new_state}
  end

  defp put_deck_length(%{deck: deck} = state) do
    deck_length = Enum.find_index(deck, &(&1 == []))
    %{state | deck_length: deck_length}
  end

  defp update_game_state(state, result) do
    state
    |> Map.put(:cols, result.cols)
    |> Map.put(:deck, result.deck)
    |> Map.put(:foundation, result.foundation)
    |> IO.inspect()
  end

  def perform_autowin_maybe(game) do
    if Game.deck_empty?(game) and Game.cols_empty?(game) do
      Task.async(fn -> Game.perform_autowin(game) end)
    end
  end

  def handle_info(msg, state) do
    IO.inspect(msg)
    {:noreply, state}
  end

  @spec check_for_autowin([any] | %{deck: [any] | %{deck: [any] | map}}) :: nil | Task.t()
  def check_for_autowin(game) do
    perform_autowin_maybe(game)
  end
end
