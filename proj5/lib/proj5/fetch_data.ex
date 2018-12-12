defmodule Proj5.FetchData do
  require Logger

  import Proj5.ChartStats

  @doc "updates all available exchange rates for 58 times"
  def update_all(timeout, startTime) do
    timeout
    |> get_and_distribute_data(startTime)
    :timer.sleep(timeout)
    update_all(timeout, startTime)
  end

  def get_and_distribute_data(timeout, startTime) do
    startTime
    |> get_chart_statistics
    |> broadcast_data
    :timer.sleep(timeout)
  end

  def broadcast_data(data) do
    #Broadcast to all participants
    Proj5Web.Endpoint.broadcast "charts:lobby", "upd_figure", %{"body" => data}
    Proj5Web.ChartChannel.update_charts(data)
  end
end
