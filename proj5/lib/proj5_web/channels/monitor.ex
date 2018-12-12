defmodule Proj5Web.ChartChannel.Monitor do
  require Logger
  use Agent

  def start_link(initial_state) do
    Logger.debug("init Monitor")
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def get_chart_state() do
    Logger.debug("init getstate")
    Agent.get(__MODULE__, fn state -> get_chart_state(state) end)
  end

  defp get_chart_state(state) do
    Logger.debug("Current get state: #{inspect(state)}")
    state
  end

  def chart_update(new_data) do
    Logger.debug("init update: #{inspect(new_data)}")
    Agent.update(__MODULE__, fn state -> chart_update(state, new_data) end)
  end

  defp chart_update(state, new_data) do
    # Logger.debug("new data update: #{inspect(new_data)}")
    case state["msg"] do
      [] ->
        new_data |> Enum.map(fn {key, val} -> {key, [[Enum.at(new_data[key], 0)], [Enum.at(new_data[key], 1)]]} end) |> Enum.into(%{})
      data ->
        new_data |> Enum.map(fn {chart, [data, time]} -> {chart, [Enum.at(state[chart], 0) ++ [data], Enum.at(state[chart], 1) ++ [time]]} end) |> Enum.into(%{})
    end
  end
end
