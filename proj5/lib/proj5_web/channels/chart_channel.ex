defmodule Proj5Web.ChartChannel do
  use Phoenix.Channel

  alias Proj5Web.ChartChannel.{Monitor}

  def join("charts:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("charts:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body}
    {:noreply, socket}
  end

  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end

  def handle_in("render_state", payload, socket) do
    chart_state = Monitor.get_chart_state()
    push socket, "render_state", chart_state
    {:noreply, socket}
  end

  def update_charts(data) do
    Monitor.chart_update(data)
  end

end
