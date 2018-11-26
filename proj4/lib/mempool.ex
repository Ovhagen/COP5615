defmodule Mempool do
  use Agent
  
  def start_link(_), do: Agent.start_link(fn -> MapSet.new end)
  
  def 
  end
end