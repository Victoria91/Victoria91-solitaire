defmodule Solitaire.Game.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  alias Solitaire.Game.Server

  def start_link(_ \\ []) do
    DynamicSupervisor.start_link(__MODULE__, [], name: global_name())
  end

  def start_game(params) when is_map(params) do
    spec = %{id: Server, start: {Server, :start_link, [params]}, restart: :transient}
    DynamicSupervisor.start_child(global_name(), spec)
  end

  def start_game(token) do
    spec = %{id: Server, start: {Server, :start_link, [%{token: token}]}, restart: :transient}
    DynamicSupervisor.start_child(global_name(), spec)
  end

  def restart_game(token, params) do
    Solitaire.Game.Supervisor.stop_game(token)
    Solitaire.Game.Supervisor.start_game(Map.merge(params, %{token: token}))
  end

  def stop_game(token) do
    pid = GenServer.whereis({:global, token})
    DynamicSupervisor.terminate_child(global_name(), pid)
  end

  def childrens_list do
    DynamicSupervisor.which_children(global_name())
  end

  def global_name, do: {:global, __MODULE__}

  @impl true
  def init(_params) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
