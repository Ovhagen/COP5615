defmodule Proj2.Messenger do
  @moduledoc """
  Documentation for Proj2.Messenger
  
  The functions in this module define various gossip modalities.
  Each function takes a list of nodes as input, and outputs a list of tuples in the form {node, neighbors}.
  """
  
  @doc """
  Defines a simple message-passing implementation.
  Each node maintains a list of messages received. When gossiping, the node sends a list of all received messages and increments its termination counter.
  When a new message is received, it is appended to the list and the termination counter is reset. Duplicate messages are ignored.
  When the termination counter reaches 10, the node terminates as converged.
  """
  def tx_fn({msgs, count}) do
    {{msgs, count+1}, msgs}
  end
  
  def rcv_fn({msgs, count}, msg) do
    new_msgs = Enum.dedup(msgs ++ msg)
	if length(new_msgs) > length(msgs), do: count = 0
	{new_msgs, count}
  end
  
  def kill_fn({msgs, count}) do
    if count < 10, do: {:ok, {msgs, count}}, else: {:kill, {msgs, count}}
  end
end