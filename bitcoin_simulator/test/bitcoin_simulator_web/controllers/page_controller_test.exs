defmodule BitcoinSimulatorWeb.PageControllerTest do
  use BitcoinSimulatorWeb.ConnCase

  test "GET /", %{} do
    conn = get(build_conn(), "/")
    assert html_response(conn, 200) =~ "Bitcoin Statistics"
  end
end
