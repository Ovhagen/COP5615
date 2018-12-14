defmodule Bitcoin.WalletTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Bitcoin.Wallet module.
  """
  
  setup do
    Bitcoin.NetworkSupervisor.start_link()
    :ok
  end
  
  test "Add a UTXO to the wallet" do
    genesis = Blockchain.genesis
    {:ok, wallet} = Bitcoin.NetworkSupervisor.start_wallet(1337)
    {:ok, 0} = Bitcoin.Wallet.get_balance(wallet)
    Bitcoin.Node.relay_tx(wallet, Block.transactions(genesis.tip.block) |> hd)
    {:ok, 1_000_000_000} = Bitcoin.Wallet.get_balance(wallet)
  end
  
  test "Request a transaction" do
    genesis = Blockchain.genesis
    {:ok, wallet} = Bitcoin.NetworkSupervisor.start_wallet(1337)
    {:ok, node} = Bitcoin.NetworkSupervisor.start_node
    :ok = Bitcoin.Wallet.join(wallet, node)
    Bitcoin.Node.relay_tx(wallet, Block.transactions(genesis.tip.block) |> hd)
    
    :ok = Bitcoin.Wallet.request_payment(wallet, 1_000_000, :crypto.strong_rand_bytes(20))
  end
  
  test "Complete a couple transactions" do
    genesis = Blockchain.genesis
    {:ok, wallet} = Bitcoin.NetworkSupervisor.start_wallet(1337)
    {:ok, wallet2} = Bitcoin.NetworkSupervisor.start_wallet
    {:ok, wallet3} = Bitcoin.NetworkSupervisor.start_wallet
    {:ok, node} = Bitcoin.NetworkSupervisor.start_node
    :ok = Bitcoin.Wallet.join(wallet, node)
    :ok = Bitcoin.Wallet.join(wallet2, node)
    :ok = Bitcoin.Wallet.join(wallet3, node)
    Bitcoin.Node.relay_tx(wallet, Block.transactions(genesis.tip.block) |> hd)
    
    value = 10_000_000
    change = 1_000_000_000 - value - 200
    :ok = Bitcoin.Wallet.request_payment(wallet, value, Bitcoin.Wallet.get_pkh(wallet2) |> elem(1))
    :ok = Bitcoin.Node.start_mining(node)
    Process.sleep(2000)
    {:ok, ^value} = Bitcoin.Wallet.get_balance(wallet2)
    {:ok, bal} = Bitcoin.Wallet.get_balance(wallet)
    assert bal >= change
    
    value = 5_000_000
    change = 10_000_000 - value - 200
    :ok = Bitcoin.Wallet.request_payment(wallet2, value, Bitcoin.Wallet.get_pkh(wallet3) |> elem(1))
    Process.sleep(1000)
    {:ok, ^value} = Bitcoin.Wallet.get_balance(wallet3)
    {:ok, bal} = Bitcoin.Wallet.get_balance(wallet2)
    assert bal >= change
  end
end