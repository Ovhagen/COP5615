defmodule Proj5.FetchData do
  require Logger

  import Proj5.ChartStats

  @doc "updates all available exchange rates for 58 times"
  def update_all(timeout) do
    timeout
    |> get_and_distribute_data
    :timer.sleep(timeout)
    update_all(timeout)
  end

  def get_and_distribute_data(timeout) do
    get_chart_statistics
    |> extract_data
    |> broadcast_data
    :timer.sleep(timeout)
  end

  def extract_data(map) do
    Logger.debug(inspect(map))

    #Nbr of messages
    %{:msg => msgs,
      :tx => txs} = map
    # Logger.debug("[#{NaiveDateTime.utc_now}] Number of messages: #{msgs}")
    # Logger.debug("[#{NaiveDateTime.utc_now}] Number of txs: #{txs}")

    map
  end

  def broadcast_data(data) do
    # messages = Enum.at(data, 0)
    Proj5Web.Endpoint.broadcast "charts:lobby", "upd_figure", %{"body" => data}
    # Logger.debug("New generated data '#{inspect(data)}' broadcasted")
  end
end
