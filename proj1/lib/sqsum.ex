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
    [last_sum + length*(2*n + 2*start - length)]
  end
  
  def next_sum(start, finish, length, n, last_sum) do
    sum = last_sum + length*(2*n + 2*start - length)
	[sum | next_sum(start, finish, length, n+1, sum)]
  end
  
  @doc """
  Finds perfect squares in a list of consecutive square sums
  
  """
  def find_squares(sums, start) do
    n = Kernel.trunc(:math.sqrt(hd(sums)))
    find_next(sums, start, n, n*n)
  end
  
  def find_next([sum | sums], n, k, target) do
    cond do
	  sum > target ->
	    find_next([sum | sums], n, k+1, target + 2*k + 1)
	  sum < target ->
	    find_next(sums, n+1, k, target)
	  sum == target ->
	    [n | find_next(sums, n+1, k+1, target + 2*k + 1)]
	end
  end
  
  def find_next(sum, n, k, target) do
    if sum == target, do: [n], else: []
  end
end