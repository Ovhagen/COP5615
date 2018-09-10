defmodule Proj1 do
  @moduledoc """
  This is project 1 in the course COP5615 Distributed Operating System Principles.

  This module defines a number of helper functions to assist in connecting to remote nodes
  for distributed operation, as well as transform the problem parameters into properly
  formatted input to streamline processing.

  Authors: Pontus Ovhagen & James Howes
  """

  @doc """
  Initializes the cluster when running the distributed version.
  All remote nodes are defined in the configuration, and the function will error if any nodes
  are not responding.
  For each node, we also retrieve the number of cores available and run a benchmark test
  to determine the relative processing speed of the node.

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
  
  @doc """
  Replies to the caller with the number of cores available on the node.

  """

  def send_cores(pid) do (send pid, {self(), System.schedulers_online}) end
  
  @doc """
  Runs a benchmark computation test, as specified in the configuration, to determine processor speed,
  and sends this result back to the caller.

  """
  
  def benchmark(pid) do
    time = :timer.tc(fn ->
	    Proj1.chunk_space(Application.get_env(:proj1, :benchmark), System.schedulers_online)
	    |> Task.async_stream(SqSum, :square_sums, [])
		|> Enum.map(fn x -> x end)
	end)
	  |> elem(0)
	send pid, {self(), 1000/time}
  end
  
  @doc """
  Divides a problem space into equal sized chunks, and formats the output so it can be used as
  input for SqSum.square_sums/1

  """
  
  def chunk_space({space, length}, chunks) do
    for n <- 0..chunks-1, do: {round(n*space/chunks + 1), round((n+1)*space/chunks), length}
  end
  
  @doc """
  Takes a list of nodes and a problem space, chunks the problem space into subproblems, and then
  assigns subproblems to each node based on its relative computational power.

  """
  
  def assign_chunks(nodes, space, length) do
    {cores, power} = Enum.reduce(nodes, {0, 0}, fn {_node, n_cores, benchmark}, {cores, power} -> {cores + n_cores, power + benchmark} end)
	chunks = Proj1.chunk_space({space, length}, max(trunc(space/10_000_000), cores))
	Enum.map_reduce(nodes, {0, length(chunks), cores, power}, fn {node, n_cores, benchmark}, {used, remaining, cores, power} ->
	  assigned = max(n_cores, min(remaining-cores+n_cores, round(remaining*benchmark/power)))
	  {{node, Enum.slice(chunks, used..used+assigned-1)}, {used + assigned, remaining - assigned, cores - n_cores, power - benchmark}}
	end)
	  |> elem(0)
  end
  
  @doc """
  Runs SqSum.square_sums/1 asynchronously, keeping track of CPU time used by each process.
  Returns the results of the computation as well as the total CPU time used.

  """

  def calc_with_timer(chunks) do
    Task.async_stream(chunks, fn chunk -> :timer.tc(SqSum, :square_sums, [chunk]) end, timeout: Application.get_env(:proj1, :timeout))
      |> Enum.reduce({0, []}, fn {:ok, {time, result}}, {cpu_time, results} ->
	      {cpu_time + time, results ++ result}
		end)
  end

end
