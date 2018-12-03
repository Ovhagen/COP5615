defmodule Proj4.MerkleTreeTest do
  use ExUnit.Case
  @moduledoc """
  This module defines a test for operations and functions in 'merkle_tree.ex'.
  """
  @tag :merkle
  setup do
    %{
      tx_test: [Transaction.test(5, 5),  #Transactions gathered by a miner.
                Transaction.test(5, 5),
                Transaction.test(5, 5),
                Transaction.test(5, 5)],
	 }
  end

  @doc """
  Test creates a merkle tree and checks that merkle nodes and leafs are set correctly. Input is four randomly generated
  transactions.
  """
  test "Use case for creating a merkle tree", %{tx_test: tx_test} do
    tree = MerkleTree.build_tree(tx_test)
    assert(tree.leaves == 4)  #Check tree size
    tx_hashes = tx_test |> Enum.map(&(Transaction.hash(&1))) #Generate the tx hashes manually
    assert(tx_hashes == [tree.root.left.left.hash, #Check tx hashes
                         tree.root.left.right.hash,
                         tree.root.right.left.hash,
                         tree.root.right.right.hash])
  end

  @doc """
  Test that the creation of a merkle proof is done correctly by comparing with the merkle path solution.
  The answer was taken from hashes of the merkle tree nodes.
  """
  test "Use case when creating a proof object", %{tx_test: tx_test} do
    tree = MerkleTree.build_tree(tx_test)
    {:ok, proof} = MerkleTree.proof(tree, Enum.at(tx_test, 1)) #Create a proof for the second transaction
    correct_path = [ #Generate the correct path manually
      tree.root.left.right.hash,
      {:left, tree.root.left.left.hash},
      {:right, tree.root.right.hash}]
    assert(proof == correct_path)
  end

  @doc """
  This test certifies that a transaction can be successfully verified to have been included in a merkle tree. The
  verification process is carried out by hashing up the merkle path and finally compare with the merkle root.
  """
  test "Successfully verifying a transaction", %{tx_test: tx_test} do
    tree = MerkleTree.build_tree(tx_test)
    {:ok, proof} = MerkleTree.proof(tree, Enum.at(tx_test, 1)) #Create a proof for the second transaction
    assert(MerkleTree.solve_proof(proof, tree.root.hash))
  end

  @doc """
  This test checks that a transaction that is not included in the merkle tree will fail a merkle proof
  generation attempt.
  """
  test "Failing to verifying a transaction not in the tree", %{tx_test: tx_test} do
    tree = MerkleTree.build_tree(tx_test)
    new_tx = Transaction.test(5, 5)
    assert(MerkleTree.proof(tree, new_tx) == :error) #Create a proof for the new transaction
  end

  @doc """
  This test checks that an invalid proof will fail a merkle proof check.
  """
  test "Failing to verifying a proof", %{tx_test: tx_test} do
    tree = MerkleTree.build_tree(tx_test)
    {:ok, proof} = MerkleTree.proof(tree, Enum.at(tx_test, 1)) #Create a proof for the second transaction
    proof = [:crypto.strong_rand_bytes(32)] ++ tl(proof)
    assert(MerkleTree.solve_proof(proof, tree.root.hash) == false) #Create a proof for the new transaction
  end

end
