defmodule Proj5.ChartStats do

  def get_chart_statistics do
    date = DateTime.utc_now
    %{msg: [:random.uniform*10_000 |> trunc(), DateTime.to_string(date)],
      tx:  [:random.uniform*1_000 |> trunc(), DateTime.to_string(date)]}
  end


end
