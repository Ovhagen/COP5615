defmodule Proj3.ChordSupervisor do
  @moduledoc """
  Documentation for Proj2.ChordSupervisor
  """
  use DynamicSupervisor

  alias Proj3.ChordNode, as: Node

  ## Client API

  @doc """
  Starts and links the Chord supervising process.
  """
  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Starts a new chord node.

  start_child/0 takes all the parameters required to initialize a chord node
  """
  def start_child() do
    DynamicSupervisor.start_child(__MODULE__, Node)
  end

  @doc """
  Starts multiple chord nodes and make them join the network.
  """
  def initialize_chord(numNodes) do
    {:ok, root_node} = start_child()
    {:ok, nodes} = start_children(root_node, numNodes)
  end

  def start_children(root_node, numNodes) do
    1..numNodes
    |> Enum.map(fn nodes -> start_child() end)
    |> Enum.reduce({:ok, []}, fn {:ok, pid}, {:ok, pids} -> {:ok, pids ++ [pid]} end)
    |> IO.inspect
  end

  def connect_nodes(numNodes) do

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
    IO.puts "Init Supervisor"
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end
end
