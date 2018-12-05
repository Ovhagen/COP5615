defmodule Proj5Web.PageController do
  use Proj5Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
