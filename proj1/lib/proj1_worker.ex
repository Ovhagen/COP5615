defmodule Proj1.Worker do

  def calculate_square(nbrSpace, nbr, seqLen, parent) do
    IO.inspect nbrSpace, label: "Started"
    result = nbr..(nbr + seqLen - 1)
    |> Enum.to_list()
    |> Enum.reduce(0, fn(x, acc) -> Pow.pow(x, 2)+acc end)
    |> Kernel.trunc()
	|> :math.sqrt()
    IO.puts result
    checkPerfect = nbr..(result)|> Enum.to_list() |> Enum.any?(fn(x) -> x > nbr and Pow.pow(x, 2) == result end)
    case checkPerfect do
      true -> send(parent, {:ok, self(), nbr |> Kernel.trunc})
      false -> Process.exit(self(), :kill)
    end
	if result - Kernel.trunc(result) == 0 do
	  send(parent, {:ok, self(), nbr |> Kernel.trunc})
	else
	  Process.exit(self(), :kill)
	end
  end

end

defmodule Pow do
require Integer

def pow(_, 0), do: 1
def pow(x, n) when Integer.is_odd(n), do: x * pow(x, n - 1)
def pow(x, n) do
  result = pow(x, div(n, 2))
  result * result
end
end
