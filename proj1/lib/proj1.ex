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
  end

end
