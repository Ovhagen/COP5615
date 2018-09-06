defmodule Proj1.Worker do
  @moduledoc """
  Documentation for Proj1.Worker
  """

  use GenServer

  @doc """
  Starting and linking the GenServer process.
  Initializing a list of tuples {start, finish, seqLen} to work with as the state.
  """
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer initialization.
  """
  @impl true
 def init(state) do
   {:ok, state}
 end

 @doc """
 GenServer.handle_call/3 callbacks
 """
 @impl true
 def handle_call(:dowork, _from, [job | state]) do
   result = SqSum.square_sums(elem(job,0), elem(job,1), elem(job,2))
   |> SqSum.find_squares(elem(job,0))
   {:reply, result, state}
 end

 @impl true
 def handle_call(:seework, _from, state) do
   {:reply, state, state}
 end

 @doc """
 GenServer.handle_cast/3 callbacks
 """
 def handle_cast({:addwork, value}, state) do
    {:noreply, state ++ [value]}
  end


  @doc """
  Helper functions to call
  """
  def start_work, do: GenServer.call(__MODULE__, :dowork)
  def work_status, do: GenServer.cast(__MODULE__, :seework)
  def add_work(value), do: GenServer.cast(__MODULE__, {:addwork, value})

end
