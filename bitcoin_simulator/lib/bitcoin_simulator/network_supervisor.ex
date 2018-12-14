defmodule Bitcoin.NetworkSupervisor do
  @moduledoc """
  This module defines a supervisor for managing the actors within the Bitcoin peer-to-peer network simulation.
  """
  use DynamicSupervisor
  
  # Client interface
  
  @doc """
  Starts and links the Network Supervisor process.
  """
  def start_link(args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end
  
  @spec start_node(non_neg_integer | nil) :: {:ok, pid}
  def start_node(seed \\ nil) do
    {:ok, wallet} = start_wallet(seed)
    neighbors = Enum.take_random(node_list(), 2)
    {:ok, node} = DynamicSupervisor.start_child(__MODULE__, {Bitcoin.Node, %{wallet: wallet, neighbors: neighbors}})
    :ok = Bitcoin.Wallet.join(wallet, node)
    {
      Enum.each(neighbors, &Bitcoin.Node.add_neighbor(&1, node)),
      node
    }
  end
  
  @spec start_wallet(non_neg_integer | nil) :: {:ok, pid}
  def start_wallet(seed \\ nil), do: DynamicSupervisor.start_child(__MODULE__, {Bitcoin.Wallet, seed})
  
  @spec start_wallets(non_neg_integer) :: {:ok, [pid, ...]}
  def start_wallets(n) do
    {
      :ok,
      Stream.repeatedly(&start_wallet/0)
        |> Enum.take(n)
        |> Enum.map(&elem(&1, 1))
    }
  end
  
  @spec start_nodes(pos_integer) :: {:ok, [pid, ...]}
  def start_nodes(n) do
    {
      :ok,
      Stream.repeatedly(&start_node/0)
        |> Enum.take(n)
        |> Enum.map(&elem(&1, 1))
    }
  end  
  
  @spec node_list() :: [pid]
  def node_list() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.filter(fn {:undefined, _pid, _type, [module]} -> module == Bitcoin.Node end)
    |> Enum.map(&elem(&1, 1))
  end
  
  @spec wallet_list() :: [pid]
  def wallet_list() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.filter(fn {:undefined, _pid, _type, [module]} -> module == Bitcoin.Wallet end)
    |> Enum.map(&elem(&1, 1))
  end
  
  # Server Callbacks
  
  @impl true
  def init(_args) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end
end