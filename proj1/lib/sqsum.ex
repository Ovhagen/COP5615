defmodule SqSum do
  @moduledoc """
  Documentation for SqSum.
  """

  @doc """
  Finds sequences of perfect squares which sum to a perfect square.
  
  """
  def square_sums({start, finish, length}) do
    sum = length*start*(start + length - 1) + Enum.reduce(1..(length-1), fn x, acc -> x*x + acc end)
	k = sum |> :math.sqrt() |> trunc()
	_check_sum(start, finish, length, sum, k, k*k, [])
  end

  defp _check_sum(n, finish, _length, _sum, _k, _k2, results) when n > finish do results end

  defp _check_sum(n, finish, length, sum, k, k2, results) do
    cond do
	  sum > k2 ->
	    _check_sum(n, finish, length, sum, k+1, k2+2*k+1, results)
	  sum < k2 ->
	    _check_sum(n+1, finish, length, sum+length*(2*n+length), k, k2, results)
	  sum == k2 ->
	    _check_sum(n+1, finish, length, sum+length*(2*n+length), k+1, k2+2*k+1, results ++ [n])
	end
  end
end