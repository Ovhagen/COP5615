defmodule Bitcoin.Node do
  @moduledoc """
  This module defines the Node actor, which serves as the fundamental unit of the Bitcoin network.
  Nodes maintain the full blockchain, and are able to validate new transactions and maintain a mempool
  of transactions which are awaiting confirmation.
  
  Each Node may also run a mining operation, in which new blocks are created and added to the blockchain.
  """
  use Genserver
  
  # Client interface
  
  def start_link(bc), do: GenServer.start_link(__MODULE__, bc)
  
  
  
  # Server callbacks
  
  def init(bc), do: {:ok, %{chain: Blocktree.new(bc)}}
end