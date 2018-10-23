defmodule Proj3.Chord do
  @moduledoc """
  This module provides functions to manage and test Chord networks.
  """
  
  @doc """
  Starts a Chord network with n nodes.
  The nodes are joined in sorted order, so the network starts with a fully connected cycle.
  """
  def initialize_chord(n, data \\ %{}) when n > 0 do
    nodes = [elem(Proj3.ChordSupervisor.start_child(data), 1)] ++ Proj3.ChordSupervisor.start_children(n-1)
      |> Enum.sort_by(&Proj3.ChordNode.get_id(&1))
    Proj3.ChordNode.start(List.last(nodes))
    Enum.chunk_every(nodes, 2, 1, :discard)
      |> Enum.each(fn [a, b] -> Proj3.ChordNode.join(a, b) end)
    # Tell the last node about the first node to complete the cycle.
    Proj3.ChordNode.notify(List.last(nodes), %{pid: hd(nodes), id: Proj3.ChordNode.get_id(hd(nodes))})
    {:ok, nodes}
  end
  
  @doc """
  Accelerate the finger indexing process by performing n random notifications across the Chord.
  """
  def index_assist(chord, n) when length(chord) > 1 and n > 0, do: index_assist(Enum.shuffle(chord), chord, n)
  def index_assist(_chord, _n), do: :ok
  
  defp index_assist(_shuffled, _chord, n) when n == 0, do: :ok
  defp index_assist(shuffled, chord, n) when length(shuffled) < 2, do: index_assist(Enum.shuffle(chord), chord, n)
  defp index_assist(shuffled, chord, n) do
    {[a, b], tail} = Enum.split(shuffled, 2)
    Proj3.ChordNode.notify(a, %{pid: b, id: Proj3.ChordNode.get_id(b)})
    index_assist(tail, chord, n-1)
  end

  @doc """
  Inserts integer key-value pairs into the chord for testing. Total keys inserted is k * size of chord.
  """
  def seed_keys(c, k) do
    Enum.chunk_every(1..length(c)*k, k)
      |> Enum.shuffle()
      |> Enum.zip(c)
      |> Task.async_stream(fn {keys, n} -> Enum.each(keys, &(Proj3.ChordNode.put(n, &1, &1))) end)
      |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
    Map.new(1..length(c)*k, &({&1, &1}))
  end

end