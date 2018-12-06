defmodule Proj5Web.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def join(_room, _message, _socket) do
    {:error, %{reason: "you can only join the lobby"}}
  end

  def handle_in("new_message", body, socket) do
    broadcast! socket, "new_message", body
    {:noreply, socket}
  end
end
