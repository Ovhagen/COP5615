defmodule Proj5Web.ChartChannel do
  use Phoenix.Channel

  def join("charts:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("charts:eur-usd-exchange", _message, socket) do
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

  def handle_in("upd_figure", %{"body" => body}, socket) do
    broadcast! socket, "upd_figure", %{body: body}
    {:noreply, socket}
  end

  def handle_out("upd_figure", payload, socket) do
    push socket, "upd_figure", payload
    {:noreply, socket}
  end

end
