defmodule Proj1Test do
  use ExUnit.Case
  doctest Proj1

  @doc """
  Individual tests for functions of finding perfect squares.
  """
  test "SumSquare test" do
    IO.puts "Running square tests..."
    assert SqSum.square_sums(1, 3, 2) |> SqSum.find_squares(1) == [3]
    assert SqSum.square_sums(1, 40, 24) |> SqSum.find_squares(1) == [1, 9, 20, 25]
    assert SqSum.square_sums(1, 1000000, 409) |> SqSum.find_squares(1) == [71752]
    assert SqSum.square_sums(1, 10000000, 409) |> SqSum.find_squares(1) == [71752, 1236640]
  end
end
