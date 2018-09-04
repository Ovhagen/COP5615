defmodule Proj1 do
  @moduledoc """
  This is project 1 in the course COP5615 Distributed Operating System Principles.

  In this project we use actor modeling to determine the perfect square of a
  consecutive sum of squares.

  Authors: Pontus Ovhagen & James Howes
  """

  @doc """
  Calculates the perfect square.

  ## Parameters

    - An integer number for the upper-bound on the search.
    - An integer number for the total length of the squared sequence.

  ## Examples

      mix run proj1.exs 3 2
      3

      mix run proj1.exs 40 24
      1

  """

  def main(args) do
    #{_, opts, _} = OptionParser.parse(args, switches: [N: :integer, seqLen: :integer], aliases: [])
    params = Enum.map_every(args, 1, fn(arg) -> String.to_integer(arg) end)
    IO.inspect params

    #Initialize input variables
    endNbr = Enum.at(params, 0)
    seqLen = Enum.at(params, 1)

    #Create search space 1 -> N+k
    searchSpace = Enum.to_list(1..endNbr)
    #IO.inspect searchSpace
    calculate_seq(searchSpace, seqLen)
  end

  defp calculate_seq(nbrSpace, seqLen) do
    Enum.each(nbrSpace,
    fn(nbr) -> spawn(Proj1.Worker, :calculate_square, [nbrSpace, nbr, seqLen, self()]) end)
    receiveResult()
  end

  defp receiveResult do
    receive do
      {:ok, sender, result} -> IO.inspect sender, label: "Result #{result} given by"
    end
  end

end
