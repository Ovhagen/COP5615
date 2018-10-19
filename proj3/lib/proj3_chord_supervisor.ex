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
  def start_link(args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Starts a new Chord node.
  Returns {:ok, pid}.
  """
  def start_child() do
    DynamicSupervisor.start_child(__MODULE__, Node)
  end
  
  @doc """
  Starts multiple Chord nodes.
  Returns {:ok, pids} where pids is a list of pids.
  """
  def start_children(n), do: start_children(n, [])
  def start_children(n, pids) when n > 0, do: start_children(n - 1, [elem(start_child(), 1)] ++ pids)
  def start_children(_n, pids), do: pids

  @doc """
  Starts a Chord network with n nodes.
  The nodes are joined in sorted order, so the network starts with a fully connected cycle.
  """
  def initialize_chord(n) do
    nodes = start_children(n)
      |> Enum.sort_by(&Node.get_id(&1))
    Node.start(List.last(nodes))
    Enum.chunk_every(nodes, 2, 1, :discard)
      |> Enum.each(fn [a, b] -> Node.join(a, b) end)
    # Tell the last node about the first node to complete the cycle.
    Node.notify(List.last(nodes), %{pid: hd(nodes), id: Node.get_id(hd(nodes))})
    {:ok, nodes}
  end
  
  @doc """
  Accelerate the finger indexing process by performing n random notifications across the Chord.
  """
  def index_assist(chord, n) when length(chord) > 1 and n > 0, do: index_assist(Enum.shuffle(chord), chord, n)
  def index_assist(_chord, _n), do: :ok
  
  defp index_assist(_shuffled, _chord, n) when n == 0, do: :ok
  defp index_assist(shuffled, chord, n) when length(shuffled) < 2, do: index_assist(Enum.shuffle(chord), chord, n)
    [[a, b], tail] = Enum.split(shuffled, 2)
    Node.notify(a, %{pid: b, id: Node.get_id(b)})
    index_assist(tail, chord, n-1)
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
    # IO.puts "Init Supervisor"
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end
end
