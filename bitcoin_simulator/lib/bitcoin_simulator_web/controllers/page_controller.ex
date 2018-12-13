defmodule BitcoinSimulatorWeb.PageController do
  use BitcoinSimulatorWeb, :controller

  def index(conn, _params), do: render conn, "index.html"

  def transactions(conn, _params), do: render conn, "transactions.html"

  def transacted(conn, _params), do: render conn, "transacted.html"

  def mined(conn, _params), do: render conn, "mined.html"

  def hashrate(conn, _params), do: render conn, "hashrate.html"
end
