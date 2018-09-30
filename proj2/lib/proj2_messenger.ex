defmodule Proj2.Messenger do
  @moduledoc """
  Defines a simple message-passing implementation, where messages take the form of atoms.
  
  ## Gossip content
  
  Each node maintains a map of messages received and the number of times each has been received. When gossiping, the node sends a list of all received messages.
  When a new message is received, it is added to the map. The message's counter is incremented each time the message is received again.
  
  ## Convergence
  
  When the counter for all messages in the map exceeds a certain value, the node converges.
  """
  def init(), do: %{}
  
  def tx_fn(msgs) do
    {msgs, Map.keys(msgs)}
  end
  
  def rcv_fn(msgs, msg) when length(msg) == 0, do: msgs
  
  def rcv_fn(msgs, msg) do
    Map.update(rcv_fn(msgs, tl(msg)), hd(msg), 1, &(&1+1))
  end
  
  def mode_fn(:send, _), do: :active
  
  def mode_fn(:receive, msgs) do
    Enum.reduce(Map.values(msgs), :active, fn val, mode ->
	  if val > Application.get_env(:proj2, :msg_count), do: :converged, else: mode
	end)
  end

end