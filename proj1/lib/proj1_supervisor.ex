defmodule Proj1.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one}
    ]
    Supervisor.init(children, strategy: :one_for_one)

    #Supervisor.count_children(pid)
  end
end
