defmodule BitcoinSimulator.ChartStats do

  def get_chart_statistics(startTime) do
    data_time = DateTime.diff(DateTime.utc_now, startTime)
    %{msg: [:rand.uniform*10_000 |> trunc(), data_time],
      tx:  [:rand.uniform*1_000 |> trunc(), data_time],
      tx_trans: [:rand.uniform*1_000 |> trunc(), data_time],
      btc_mined: [:rand.uniform*100 |> trunc(), data_time],
      hash_rate: [:rand.uniform*1_000_000 |> trunc(), data_time]
      }
  end
end
