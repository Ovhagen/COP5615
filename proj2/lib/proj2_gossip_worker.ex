defmodule Proj2.GossipWorker do
  @moduledoc """
  Documentation for Proj2.GossipWorker
  """
  use GenServer

  @doc """
  Starting and linking the GenServer process.
  Initializing a node in the network.
  The state holds three elements: the convergence number, number of received messages
  at the start and the neighbors of a node.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @doc """
  GenServer initialization.
  """
  @impl true
 def init(state) do
   {:ok, state}
 end

 @doc """
 GenServer.handle_call/2 callbacks
 """
 @impl true
 def handle_call(:start, _from, state) do
   IO.puts "#{inspect(self())}: Got it boss! I will start the rumor."
   send_message(state)
   {:reply, :ok, state}
 end

 @impl true
 def handle_cast({:setneighbors, neighbors}, state) do
   IO.puts "#{inspect(self())}: Got it boss! Adding neighbors #{inspect(neighbors)}."
   {:noreply, List.update_at(state, 2, fn x -> x = neighbors end)}
 end

 @doc """
 GenServer.handle_info/2 callbacks

 Invoced when a message has been received.
 Updates the state of received messages.
 Either just sends a new message or sends a finish request to the boss when converged.
 """
 @impl true
 def handle_info(:doincrement, state) do
   IO.puts "#{inspect(self())}: Boss. Got a message from someone!"
   state = update_state(state)
   if Enum.at(state, 1) == Enum.at(state, 0) do
      IO.puts "#{inspect(self())}: Im finished boss!"
      send_message(state)
      send Enum.at(state, 3), {:finished, self()}
      terminate("Finished", state) #Should we terminate in child or parent? Parent would be optimal.

   else if Enum.at(state, 1) < Enum.at(state, 0) do
     send_message(state)
   end

   end
   {:noreply, state}
 end

 @doc """
 Function for sending a message to a random neighbor.
 """
 defp send_message(state) do
   IO.puts "#{inspect(self())}: Sending a new message! #{inspect(Enum.at(state,1))} received."
   send(Enum.random(Enum.at(state,2)), :doincrement)
 end

 @doc """
 Function for updating the state.
 """
 defp update_state(state) do
   IO.puts "#{inspect(self())}: Updating!"
   List.update_at(state, 1, fn x -> x = x + 1 end)
 end

  @doc """
  Helper functions to call
  """
  #def start_node(pid), do: GenServer.call(pid, :start)
  #def set_neighbors(pid, nodes), do: GenServer.cast(pid, {:setneighbors, nodes})

end
