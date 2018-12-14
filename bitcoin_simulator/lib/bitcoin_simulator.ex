defmodule BitcoinSimulator do
  @moduledoc """
  Helper functions for the simulation.
  """
  
  @doc """
  This function generates transactions randomly in order to simulate traffic on the network.
  """
  def tx_generator(wallets, freq) do
    [payor, payee] = Enum.take_random(wallets, 2)
    {:ok, balance} = Bitcoin.Wallet.get_balance(payor)
    if balance > 0 do
      value = (balance*0.75) |> trunc |> :rand.uniform |> Kernel.+(balance*0.05) |> trunc
      with :ok <- Bitcoin.Wallet.request_payment(payor, value, Bitcoin.Wallet.get_pkh(payee) |> elem(1)) do
        Process.sleep(min(trunc(1000/freq), 1))
      end
    end
    tx_generator(wallets, freq)
  end
  
  def simulation(nodes, wallets, freq) do
    # Start nodes
    {:ok, nodes} = Bitcoin.NetworkSupervisor.start_nodes(nodes)

    # Start wallets (individual users) connected to each node
    Enum.each(nodes, fn node ->
      {:ok, wallets} = Bitcoin.NetworkSupervisor.start_wallets(wallets)
      Enum.each(wallets, fn wallet -> Bitcoin.Wallet.join(wallet, node) end)
    end)

    # Create the "genesis" wallet which can spend the genesis coins
    with {:ok, wallet} <- Bitcoin.NetworkSupervisor.start_wallet(1337),
         :ok           <- Bitcoin.Wallet.join(wallet, hd(nodes)),
         genesis       <- Blockchain.genesis,
         :ok           <- Bitcoin.Node.relay_tx(wallet, Block.transactions(genesis.tip.block) |> hd)
    do
      # Start mining
      Enum.each(nodes, &Bitcoin.Node.start_mining/1)
      
      # Start transaction generator
      Task.start_link(BitcoinSimulator, :tx_generator, [Bitcoin.NetworkSupervisor.wallet_list, freq])
    end
  end
end
