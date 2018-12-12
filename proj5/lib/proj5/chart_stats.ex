defmodule Proj5.ChartStats do

  def get_chart_statistics(startTime) do
    data_time = DateTime.diff(DateTime.utc_now, startTime)
    %{msg: [:random.uniform*10_000 |> trunc(), data_time],
      tx:  [:random.uniform*1_000 |> trunc(), data_time],
      tx_trans: [:random.uniform*1_000 |> trunc(), data_time],
      btc_mined: [:random.uniform*100 |> trunc(), data_time],
      hash_rate: [:random.uniform*1_000_000 |> trunc(), data_time]
      }
  end


end
