# Start network supervisor
Bitcoin.NetworkSupervisor.start_link()

# Start 20 nodes
{:ok, nodes} = Bitcoin.NetworkSupervisor.start_nodes(20)

# Start 5 wallets (individual users) connected to each node
Enum.each(nodes, fn node ->
  {:ok, wallets} = Bitcoin.NetworkSupervisor.start_wallets(5)
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
  Task.start(BitcoinSimulator, :tx_generator, [Bitcoin.NetworkSupervisor.wallet_list, 10])
end

Process.sleep(30_000)