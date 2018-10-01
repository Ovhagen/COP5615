defmodule Proj2.NetworkManager do
  @moduledoc """
  Documentation for Proj2.NetworkManager
  """
  use DynamicSupervisor
  
  alias Proj2.GossipNode, as: Node
  
  ## Client API
  
  @doc """
  Starts and links the Network Manager process.
  """
  def start_link(args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end
  
  @doc """
  Starts a new GossipNode under the NetworkManager.
  
  ## Parameters
    - data:    Initial state.
    - tx_fn:   Function which is invoked on the current state to determine the data to send to neighboring nodes while gossiping.
	           Must take one argument (the current state) and output a tuple with the new state and the data to send.
    - rcv_fn:  Function which is invoked on the current state and the data received during gossiping.
               Must take two arguments (current state and received data) and output the new state.
    - mode_fn: Function which is invoked after both transmitting and receiving to determine continuing mode of operation.
               Must take an atom (:send or :receive) and the current state as arguments, and return an atom representing the current mode of operation.
  """
  def start_child(data, tx_fn, rcv_fn, mode_fn) do
    DynamicSupervisor.start_child(__MODULE__, Supervisor.child_spec(
	  {Node,
	    %{mode:      :passive,
		  data:      data,
		  neighbors: [],
		  sent:      0,
		  tx_fn:     tx_fn,
		  rcv_fn:    rcv_fn,
		  mode_fn:   mode_fn}
      }, restart: :temporary))
  end
  
  def start_child(module, args \\ []) do
    start_child(apply(module, :init, args),
	          &(apply(module, :tx_fn, [&1])),
		      &(apply(module, :rcv_fn, [&1, &2])),
			  &(apply(module, :mode_fn, [&1, &2, &3])))
  end
  
  @doc """
  Starts multiple new GossipNodes under the NetworkManager, all with the same configuration. Number of nodes to start
  is determined by the length of the data parameter.
  
  ## Parameters
    - data:  List containing initial data. One node will be started for each element.
    - See start_child/4 for explanation of remaining parameters.
  """
  def start_children(data, tx_fn, rcv_fn, mode_fn) do
    data
	  |> Enum.map(fn datum -> start_child(datum, tx_fn, rcv_fn, mode_fn) end)
	  |> Enum.reduce({:ok, []}, fn {:ok, pid}, {:ok, pids} -> {:ok, pids ++ [pid]} end)
  end
  
  def start_children(module, args) do
    start_children(Enum.map(args, &(apply(module, :init, &1))),
	             &(apply(module, :tx_fn, [&1])),
		         &(apply(module, :rcv_fn, [&1, &2])),
			     &(apply(module, :mode_fn, [&1, &2, &3])))
  end
  
  @doc """
  Creates a network across the active GossipNodes by assigning neighbors using the desired topology function.
  
  ## Parameters
    - sup:         PID of the NetworkManager
    - topology_fn: Function which is invoked on the list of active GossipNodes and returns a list of tuples in the form {node, [neighbors]}
  """
  def set_network(topology_fn) do
    DynamicSupervisor.which_children(__MODULE__)
	  |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	  |> topology_fn.()
	  |> Task.async_stream(fn {node, neighbors} -> Node.update(node, :neighbors, fn _ -> neighbors end) end)
	  |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
  end
  
  def reset(module, data) do
    nodes =
	  DynamicSupervisor.which_children(__MODULE__)
	    |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	:ok =
	  Task.async_stream(nodes, Node, :stop, [])
	    |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
    Process.sleep(Application.get_env(:proj2, :delay) * 3)  # Make sure all :transmit messages are cleared
	Enum.map(data, &(apply(module, :init, &1)))
	  |> Enum.zip(nodes)
	  |> Task.async_stream(fn {data, node} -> Node.reset(node, data) end)
	  |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
  end
  
  def kill_children() do
    DynamicSupervisor.which_children(__MODULE__)
	  |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	  |> Task.async_stream(fn pid -> DynamicSupervisor.terminate_child(__MODULE__, pid) end)
	  |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
  end
  
  ## Server Callbacks
  
  @impl true
  def init(_args) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end
end