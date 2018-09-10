defmodule SqSum do
  @moduledoc """
  Documentation for SqSum.
  """

  @doc """
  Finds sequences of perfect squares which sum to a perfect square.
  The algorithm runs in roughly linear time, as each sum is computed with simple integer addition from the previous sum,
  and perfect squares are checked without needing to take the square root of every sum. Furthermore, the function has
  been written to be tail-recursive so it does not build up a deep stack and requires very little memory.
  
  The arguments are wrapped in a tuple in order to facilitate pipelining.
  
  The public function starts the computation by calculating the first sum in the sequence, and then choosing a "target"
  perfect square. The sum and the target are passed to the private helper function _check_sum/7 which performs the recursion.
  
  In each iteration of the helper function, the sum is compared to the target perfect square (k2).
  
  If k2 is too low, then it is incremented to the next perfect square through fast addition
  and the function recurses.
  
  If k2 is too high, then the sum is incremented to the next in the sequence through fast addition
  and the function recurses.
  
  When the sum matches k2 we have found a perfect square. Append it to the end of the results list,
  and increment both the sum and the target to the next values.
  
  The recursion terminates when we have iterated beyond finish, and the results list is returned.
  
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