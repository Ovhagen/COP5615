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
  def start_link(args \\ %{}) do
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
  Handle request to monitor network, and initialize mapping of node states.
  """
  @impl true
  def handle_call({:monitor, sup}, _from, _state) do
    {:reply, :ok,
      DynamicSupervisor.which_children(sup)
	    |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	    |> Map.new(fn pid -> {pid, :ok} end)}
  end
  
  @doc """
  Record convergence of monitored nodes.
  """
  @impl true
  def handle_call(:converged, from, state) do
    state = Map.put(state, from, :converged)
	IO.inspect Enum.reduce(Map.values(state), 0, &(if &1 == :converged, do: &2 + 1, else: &2)) 
	if converged?(Map.values(state)), do: {:stop, :normal, :ok, state}, else: {:reply, :ok, state}
  end
  
  defp converged?(nodes) when length(nodes) == 0, do: :true
  
  defp converged?(nodes), do: (if hd(nodes) == :converged, do: converged?(tl(nodes)), else: :false)
end