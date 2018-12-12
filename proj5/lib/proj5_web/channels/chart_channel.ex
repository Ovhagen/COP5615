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

  # def handle_in("upd_figure", %{"body" => body}, socket) do
  #   IO.puts("yyyyyyyyyyyyyaaaaaaayyyyyyy")
  #   broadcast! socket, "upd_figure", %{body: body}
  #   {:noreply, socket}
  # end

  def handle_in("render_state", payload, socket) do
    chart_state = Monitor.get_chart_state()
    push socket, "render_state", chart_state
    {:noreply, socket}
  end

  def handle_in("upd_state", %{"body" => data}, socket) do
    Monitor.chart_update(data)
    #TODO For multiple sessions make sure updates are timely
    # new_time = Enum.at(data["msg"], 1) |> DateTime.from_iso8601()
    # {:ok, new_time, diff} = DateTime.diff(new_time, socket.assigns[:last_update_time])
    # IO.puts("mega difference #{inspect(abs(DateTime.diff(new_time, socket.assigns[:last_update_time])))}")
    # if abs(diff) > 0 do
    #   socket = assign(socket, :last_update_time, new_time)
    # end
    {:noreply, assign(socket, :chartData, Monitor.get_chart_state())}
  end

end
