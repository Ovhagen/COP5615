defmodule Proj1.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_)do
    children = [
      {Proj1.Worker, [{1, 3, 2}]}
    ]
    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

    #Supervisor.count_children(pid)
  end
end
