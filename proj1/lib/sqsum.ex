defmodule SqSum do
  @moduledoc """
  Documentation for SqSum.
  """

  @doc """
  Calculates the sum of squares of consecutive integers.

  """
  def square_sums(start, finish, length) do
    sum = length*start*(start + length - 1) + Enum.reduce(1..(length-1), fn x, acc -> x*x + acc end)
	[sum | next_sum(start, finish, length, length, sum)]
  end

  @doc """
  Helper function for square_sums
  Calculates the next sum in the sequence
  
  """
  def next_sum(start, finish, length, n, last_sum) when n >= finish - start + length - 1 do
    last_sum + length*(2*n + 2*start - length)
  end
  
  def next_sum(start, finish, length, n, last_sum) do
    sum = last_sum + length*(2*n + 2*start - length)
	[sum | next_sum(start, finish, length, n+1, sum)]
  end
end
