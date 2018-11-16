defmodule Proj4.MerkleTreeTest do
  use ExUnit.Case

  setup do
    %{
	  tx_test1: ["3e4bb40f066d195155e74eb0d26d644fbf5cab91", "ca3bce4f810bca6f68fcecd1b79627c06016f142", "ced1f2728fe4e928716a639cda1333af67eafeea", "0710260689d3f95eb18bdfb0235ffcf4cd728045"],
    arity_test: ["3e4bb40f066d195155e74eb0d26d644fbf5cab91", "ca3bce4f810bca6f68fcecd1b79627c06016f142", "ced1f2728fe4e928716a639cda1333af67eafeea"]
	 }
  end

  test "General use case", %{tx_test1: tx_test1} do
    tree = MerkleTree.makeMerkle(tx_test1)
    assert(tree.root.hash_value == "bae2b3a1a01b4e555b9566f09e541661239c3199e9f2819af5d8563bce13ddd4")
  end

  test "Power arity failure", %{arity_test: arity_test} do
    assert_raise(MerkleTree.PowerError, fn () -> MerkleTree.makeMerkle(arity_test) end)
  end

  test "No argument failure" do
    assert_raise(FunctionClauseError, fn () -> MerkleTree.makeMerkle([]) end)
  end

end
