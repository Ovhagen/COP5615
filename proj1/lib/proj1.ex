defmodule Proj1 do
  @moduledoc """
  This is project 1 in the course COP5615 Distributed Operating System Principles.

  In this project we use actor modeling to determine the perfect square of a
  consecutive sum of squares.

  Authors: Pontus Ovhagen & James Howes
  """

  @doc """
  Calculates the perfect square.

  ## Parameters

    - An integer number for the upper-bound on the search.
    - An integer number for the total length of the squared sequence.

  ## Examples

      mix run proj1.exs 3 2
      3

      mix run proj1.exs 40 24
      1

  """

  def init_cluster() do
    Node.start(:master)
    master = self()
    Application.get_env(:proj1, :nodes)
	  |> Enum.map(fn node -> {node, Node.connect(node)} end)
	  |> Enum.map(fn {node, :true} -> {node, Node.spawn(node, Proj1, :send_cores, [master])} end)
	  |> Enum.map(fn {node, pid} -> receive do {^pid, cores} -> {node, cores} end end)
  end
  
  def send_cores(pid) do (send pid, {self(), System.schedulers_online}) end

end
