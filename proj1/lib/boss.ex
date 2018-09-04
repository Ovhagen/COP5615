defmodule Proj1.Boss do
#Sacing this code for later
"""
  use Supervisor

  def start_link do
    #Supervisor.start_link([{Task.Supervisor, name: Proj1}])
  end

  task = Task.aync(fn -> calculateSequence())

  task = Task.Supervisor.async(pid, fn -> C  end)
  Task.await(task)

  def init([]) do
    children = [
      %{id: Stack,
        start: {Stack, :start_link, [[:hello]]}}
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

    Supervisor.count_children(pid)
  end

end

defmodule CalculateSequence do
  use Task

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(arg) do
    # ...
  end
"""
end


"""
defmodule Stack do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, head}, tail) do
    {:noreply, [head | tail]}
  end
end
"""
