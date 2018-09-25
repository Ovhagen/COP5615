defmodule Proj2.Topology do
  @moduledoc """
  Documentation for Proj2.Topology
  
  The functions in this module define various network topologies.
  Each function takes a list of nodes as input, and outputs a list of tuples in the form {node, neighbors}.
  """
  
  @doc """
  Defines a fully-connected network, where each node is a neighbor of every other node.
  """
  def full(nodes) do
    Enum.map_reduce(nodes, tl(nodes), fn node, acc -> {{node, acc}, tl(acc) ++ [node]} end) |> elem(0)
  end
end