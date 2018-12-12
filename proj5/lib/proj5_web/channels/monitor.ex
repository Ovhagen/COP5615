defmodule Proj5Web.ChartChannel.Monitor do
  require Logger
  use Agent
  @max_size 120

  def start_link(initial_state) do
    Logger.debug("init Monitor")
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def get_chart_state() do
    Logger.debug("init getstate")
    Agent.get(__MODULE__, fn state -> get_chart_state(state) end)
  end

  defp get_chart_state(state) do
    # Logger.debug("State for client: #{inspect(state)}")
    state
  end

  def chart_update(new_data) do
    Agent.update(__MODULE__, fn state -> chart_update(state, new_data) end)
  end

  defp chart_update(state, new_data) do
    case state[:msg] do
      nil ->
        new_data |> Enum.map(fn {key, val} -> {key, [[Enum.at(new_data[key], 0)], [Enum.at(new_data[key], 1)]]} end) |> Enum.into(%{})
      data ->
        #Reduce data stored to only be of length @max_size
        elem_data = List.first(state[:msg])
        current_length = length(if elem_data == nil do [] else elem_data end)
        new_state = (if current_length >= @max_size do
          state
          |> Enum.map(fn {key, [[head_x|x],[head_y|y]]} -> {key, [x,y]} end) |> Enum.into(%{})
        else
          state
        end)
        new_data |> Enum.map(fn {chart, [data, time]} -> {chart, [Enum.at(new_state[chart], 0) ++ [data], Enum.at(new_state[chart], 1) ++ [time]]} end) |> Enum.into(%{})
    end
  end
end
