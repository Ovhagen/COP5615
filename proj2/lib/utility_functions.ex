defmodule UtilityFunctions do

  def map_children(pid) do
    #Map the children
    pid |>
    Supervisor.which_children() |>
    Enum.map (fn{_nbr, child_pid, _type, _mod} -> child_pid end)
  end

  #Rolls the neoighbors of a node based on topology used
  def roll_neighbors(pids, topology) do
    case topology do
      "full" ->
        [{Enum.at(pids, 0), [Enum.at(pids, 1)]}, {Enum.at(pids, 1), [Enum.at(pids, 0)]}]
    end
  end
end
