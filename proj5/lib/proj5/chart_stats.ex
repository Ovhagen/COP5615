defmodule Proj5.ChartStats do

  def get_chart_statistics(startTime) do
    data_time = DateTime.diff(DateTime.utc_now, startTime)
    IO.puts("TTTIIMMEE: #{inspect(data_time)}")
    %{msg: [:random.uniform*10_000 |> trunc(), data_time],
      tx:  [:random.uniform*1_000 |> trunc(), data_time]}
  end


end
