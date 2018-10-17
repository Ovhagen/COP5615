defmodule Proj3.ChordObserver do
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
  def init([from, requests]) do
    IO.puts "Init Observer"
    {:ok, %{pids: %{}, from: from, requests: requests, finished: :false}}
  end

  @doc """
  Handle request to monitor network, and initialize mapping of node states.
  """
  @impl true
  def handle_call({:monitor, sup}, _from, state) do
    IO.puts "Observer: Monitor"
    IO.inspect state
    {:reply, :ok, Map.put(state, :pids,
      DynamicSupervisor.which_children(sup)
	    |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	    |> Map.new(fn pid -> {pid, :ok} end)) |> IO.inspect}
  end

  @doc """
  Handle request to check if network has converged.
  """
  @impl true
  def handle_call(:converged?, _from, state), do: {:reply, Map.get(state, :converged?), state}

  @doc """
  Record convergence of monitored nodes.
  """
  @impl true
  def handle_cast({:converged, pid, datum}, %{pids: pids} = state) do
    {:noreply,
	  Map.put(state, :pids, Map.put(pids, pid, :converged))
	    |> Map.update!(:data, &([datum] ++ &1)),
	 {:continue, :check_convergence}}
  end

  @doc """
  Handle timeout while waiting for convergence.
  """
  @impl true
  def handle_info(:timeout, %{from: from} = state) do
    send(from, :timeout)
	{:noreply, state}
  end

  @doc """
  Check complete convergence of monitored nodes.
  """
  @impl true
  def handle_continue(:check_convergence, %{pids: pids, from: from, data: data} = state) do
    if converged?(Map.values(pids)) do
	  send from, {:converged,
	               data,
	               Task.async_stream(Map.keys(pids), &(Proj2.GossipNode.get(&1, :sent, :infinity)), timeout: 10*length(Map.keys(pids)))
				     |> Enum.map(fn {:ok, n} -> n end)
	                 |> Enum.sum()}
	end
	{:noreply, state, 10_000}
  end

  defp converged?(nodes) when length(nodes) == 0, do: :true

  defp converged?(nodes), do: (if hd(nodes) == :converged, do: converged?(tl(nodes)), else: :false)
end
