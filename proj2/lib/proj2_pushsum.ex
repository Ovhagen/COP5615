defmodule Proj2.PushSum do
  @moduledoc """
  Documentation for Proj2.PushSum
  
  Defines a push-sum implementation, which converges to the average value across all nodes.
  
  ## Gossip content
  
  Each node maintains a value and weight. When gossiping, the node divides its value and weight in half, and sends half to a neighbor.
  When gossip is received, it is added to the node's current value and weight.
  
  ## Convergence
  
  Each time a node receives a message, it compares the new sum/weight ratio with the previous ratio. If the ratio has not changed by more than 1e-11, the convergence counter is reset to 0. Otherwise, it is incremented. When the convergence counter reaches a limit, the node converges. This limit is specified in the pushsum: :count configuration.
  
  To prevent nodes from converging before receiving any messages, set the intial ratio to any value other than the actual starting v/w ratio.
  """
  def init(v, w \\ 1, r \\ 0), do: {v, w, r, 0}

  def tx_fn({v, w, r, count}) do
    count =
	  if abs(r-v/w) > Application.get_env(:proj2, :epsilon) do
	    0
	  else
	    count + 1
	  end
    {{v/2, w/2, v/w, count}, {v/2, w/2}}
  end
  
  def rcv_fn({v, w, _r, count}, {v2, w2}) do
    {v+v2, w+w2, v/w, count}
  end
  
  def mode_fn(:send, _mode, {_, _, _, count}) do
    if count < Application.get_env(:proj2, :ps_count), do: :active, else: :stopped
  end
  
  def mode_fn(:receive, _mode, _state), do: :active
  
end