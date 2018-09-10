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
	  |> Enum.map(fn {node, :true} -> {node,
		  Node.spawn(node, Proj1, :send_cores, [master]),
		  Node.spawn(node, Proj1, :benchmark, [master])}
		end)
	  |> Enum.map(fn {node, pid, pid2} -> receive do {^pid, cores} -> {node, cores, pid2} end end)
	  |> Enum.map(fn {node, cores, pid2} -> receive do {^pid2, benchmark} -> {node, cores, benchmark} end end)
  end
  
  def send_cores(pid) do (send pid, {self(), System.schedulers_online}) end
  
  def benchmark(pid) do
    time = :timer.tc(fn ->
	    Proj1.chunk_space(Application.get_env(:proj1, :benchmark))
	    |> Task.async_stream(SqSum, :square_sums, [])
		|> Enum.map(fn x -> x end)
	  end)
	  |> elem(0)
	send pid, {self(), time}
  end
  
  def chunk_space({space, length}) do
    for n <- 0..System.schedulers_online-1, do: {round(n*space/System.schedulers_online + 1), round((n+1)*space/System.schedulers_online), length}
  end

end
