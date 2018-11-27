# defmodule Proj4.MerkleTreeTest do
#   use ExUnit.Case
#   @moduledoc """
#   This module defines a test for operations and functions in 'merkle_tree.ex'.
#   """
#
#   setup do
#     %{
#       tx_test1: ["c5246e478e0a319c099f94fe8e5b8c7b767a017f55408ebde477d0578659b4a8",  #Transactions gathered by a miner.
#                   "9ac0240b5e74ebaf38efa72e105cfeb06ee119dae56954dbd4f76cd790c738a5",
#                   "f25a13422d5cc7bb4331607502360cba53ceb6977623b3b4759fe96e42fdb1c8",
#                   "ce249be4a7f827ebccf51beb3d4cc919ee03b2aa51e4a3444142568d46a31a8a"],
#     arity_test: ["c5246e478e0a319c099f94fe8e5b8c7b767a017f55408ebde477d0578659b4a8", "9ac0240b5e74ebaf38efa72e105cfeb06ee119dae56954dbd4f76cd790c738a5", "f25a13422d5cc7bb4331607502360cba53ceb6977623b3b4759fe96e42fdb1c8"]
# 	 }
#   end
#
#   @doc """
#   Test creates a merkle tree and checks that the root is correct.
#   """
#   test "General use case", %{tx_test1: tx_test1} do
#     tree = MerkleTree.makeMerkle(tx_test1)
#     assert(tree.root.hash_value == "ffd2716e4f1f776214b3cd1713f2fa1b8714c775a1654a6ad6fe7372e5ee475a")
#   end
#
#   @doc """
#   Test that a failure is thrown when the number of transactions are not a power of 2.
#   """
#   test "Power arity failure", %{arity_test: arity_test} do
#     assert_raise(MerkleTree.PowerError, fn () -> MerkleTree.makeMerkle(arity_test) end)
#   end
#
#   @doc """
#   Test that a failure is thrown when an empty input is given.
#   """
#   test "No argument failure" do
#     assert_raise(FunctionClauseError, fn () -> MerkleTree.makeMerkle([]) end)
#   end
#
# end
