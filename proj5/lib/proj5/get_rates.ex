defmodule Proj5.GetRates do
  require Logger

  import Proj5.ExchangeRates

  @doc "updates all available exchange rates for 58 times"
  def update_all do
    get_and_distribute_exchange_rate
    :timer.sleep(1000)
    update_all
  end

  def get_and_distribute_exchange_rate do
    get_exchange_rate
    |> extract_exchange_rate
    |> distribute_exchange_rate
    :timer.sleep(1000)
  end

  def extract_exchange_rate(map) do
    Logger.debug(inspect(map))
    %{:rate => rate} = map
    Logger.debug("Rate is: #{rate}")
    rate
  end

  def distribute_exchange_rate(rate) do
    Proj5Web.Endpoint.broadcast "charts:lobby", "upd_figure", %{"body" => rate}
    Logger.debug("New exchange rate '#{rate}' broadcasted")
  end
end
