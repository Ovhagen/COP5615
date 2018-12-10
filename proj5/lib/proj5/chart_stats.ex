defmodule Proj5.ChartStats do

  def get_chart_statistics do
    %{nbrOfMessages: :random.uniform*10_000 |> trunc()}
  end


end
