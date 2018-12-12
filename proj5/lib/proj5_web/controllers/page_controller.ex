defmodule Proj5Web.PageController do
  use Proj5Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def transactions(conn, _params) do
    render conn, "transactions.html"
  end

  def transacted(conn, _params) do
    render conn, "transacted.html"
  end

  def mined(conn, _params) do
    render conn, "mined.html"
  end

  def hashrate(conn, _params) do
    render conn, "hashrate.html"
  end

end
