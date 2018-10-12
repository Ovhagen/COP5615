defmodule Proj3.ChordSupervisor do
  @moduledoc """
  Documentation for Proj2.ChordSupervisor
  """
  use DynamicSupervisor

  alias Proj2.ChordNode, as: Node

  ## Client API

  @doc """
  Starts and links the Network Manager process.
  """
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Starts a new GossipNode under the NetworkManager.

  start_child/0 takes all the parameters required to initialize a GossipNode
  """
  def start_child() do
    DynamicSupervisor.start_child(__MODULE__, Supervisor.child_spec(
  	  {Node, %{}},
      restart: :temporary)
    )
  end

  @doc """
  Starts multiple chord_nodes and make them join the network.
  """
  def initialize_chord(numNodes) do
    root_node = start_child() |> elem(1)
    #root_node.create()
    start_children(root_node, numNodes)
  end

  def start_children(root_node, numNodes) do
    1..numNodes
    |> Enum.map(fn nodes -> start_child() end)
    |> Enum.reduce({:ok, []}, fn {:ok, pid}, {:ok, pids} -> {:ok, pids ++ [pid]} end)
    |> inspect()
  end

  @doc """
  """
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
