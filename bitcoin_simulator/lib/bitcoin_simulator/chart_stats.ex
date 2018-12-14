defmodule BitcoinSimulator.ChartStats do
  def get_chart_statistics(startTime) do
    node = hd(Bitcoin.NetworkSupervisor.node_list)
    {:ok, bc} = Bitcoin.Node.get_mining_data(node)
    
    data_time = DateTime.diff(DateTime.utc_now, startTime)
    %{msg: [:rand.uniform*10_000 |> trunc(), data_time],
      tx:  [tx_count(bc.tip, 0), data_time],
      tx_trans: [:rand.uniform*1_000 |> trunc(), data_time],
      btc_mined: [:rand.uniform*100 |> trunc(), data_time],
      hash_rate: [:rand.uniform*1_000_000 |> trunc(), data_time]
      }
  end
  
  def tx_count(nil, sum), do: sum
  def tx_count(link, sum), do: tx_count(link.prev, sum + link.block.tx_counter)
end
