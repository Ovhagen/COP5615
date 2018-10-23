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
  def start_child(args \\ %{}) do
    DynamicSupervisor.start_child(__MODULE__, {Node, args})
  end
  
  @doc """
  Starts multiple Chord nodes.
  Returns {:ok, pids} where pids is a list of pids.
  """
  def start_children(n), do: start_children(n, [])
  def start_children(n, pids) when n > 0, do: start_children(n - 1, [elem(start_child(), 1)] ++ pids)
  def start_children(_n, pids), do: pids

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
