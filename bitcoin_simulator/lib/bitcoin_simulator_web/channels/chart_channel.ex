defmodule BitcoinSimulatorWeb.ChartChannel do
  use Phoenix.Channel

  alias BitcoinSimulatorWeb.ChartChannel.{Monitor}

  def join("charts:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("charts:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("render_state", _payload, socket) do
    chart_state = Monitor.get_chart_state()
    push socket, "render_state", chart_state
    {:noreply, socket}
  end

  def update_charts(data) do
    Monitor.chart_update(data)
  end

end
