defmodule Proj2.Observer do
  @moduledoc """
  Documentation for Proj2.Observer
  """
  
  use GenServer
  
  ## Client API
  
  @doc """
  Starting and linking the GenServer process.
  Initializing a node in the network.
  The state holds three elements: the convergence number, number of received messages
  at the start and the neighbors of a node.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end
  
  def monitor_network(sup) do
    GenServer.call(__MODULE__, {:monitor, sup})
  end
  
  ## Server Callbacks

  @doc """
  GenServer initialization.
  """
  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Handle request to monitor network.
  """
  @impl true
  def handle_call({:monitor, sup}, _from, _state) do
    refs = DynamicSupervisor.which_children(sup)
	  |> Enum.map(fn {:undefined, pid, _type, _modules} -> {pid, Process.monitor(pid)} end)
	{:reply, :ok, refs}
  end
  
  @doc """
  Catch terminations of monitored nodes.
  """
  @impl true
  def handle_info({:DOWN, ref, :process, pid, :normal}, refs) do
    refs = List.delete(refs, {pid, ref})
	if length(refs) > 0, do: {:noreply, refs}, else: {:stop, :normal, refs}
  end
end