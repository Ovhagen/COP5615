defmodule BitcoinSimulator.FetchData do
  import BitcoinSimulator.ChartStats

  @doc "updates all available exchange rates for 58 times"
  def update_all(timeout, startTime) do
    get_and_distribute_data(startTime)
    Task.start(fn ->
      Process.sleep(timeout)
      update_all(timeout, startTime)
    end)
  end

  def get_and_distribute_data(startTime) do
    startTime
    |> get_chart_statistics
    |> broadcast_data
  end

  def broadcast_data(data) do
    #Broadcast to all participants
    BitcoinSimulatorWeb.Endpoint.broadcast "charts:lobby", "upd_figure", %{"body" => data}
    BitcoinSimulatorWeb.ChartChannel.update_charts(data)
  end
end