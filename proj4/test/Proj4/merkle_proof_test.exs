defmodule Proj4.MerkleProofTest do
  use ExUnit.Case

  setup do
    %{
	  tx_test: ["3e4bb40f066d195155e74eb0d26d644fbf5cab91",  #Taken from a blocks transaction list
                "ca3bce4f810bca6f68fcecd1b79627c06016f142",
                "ced1f2728fe4e928716a639cda1333af67eafeea",
                "0710260689d3f95eb18bdfb0235ffcf4cd728045"],
      target_tx: "3e4bb40f066d195155e74eb0d26d644fbf5cab91",
      target_idx: 0,  #Given by target txs position in tx list
      tx_count: 4,  #The transaction count from the block
      merkle_path: ["7853d08f19cbdec01cb95613771670650b2967aafbc02cf7fdd69047551fa465",
                   "ffe1f2421d57dc07f5f0c13b439ad80cff78a0f5683a5faa9d0fab4d1bc92a2a",
                   "fc73efaf5dae1dca1c1bdf0c3d2f59dec282a3951f42524fabe1da0e49278518",
                   "bae2b3a1a01b4e555b9566f09e541661239c3199e9f2819af5d8563bce13ddd4"],
    target_tx_fail: "3e4bb40f066d195155e74eb0d26d644fbf5cab9"  #Removed one letter
	 }
  end

  test "Use case when creating a proof object", %{tx_test: tx_test, target_tx: target_tx, target_idx: target_idx, tx_count: tx_count, merkle_path: merkle_path} do
    tree = MerkleTree.makeMerkle(tx_test)
    proof = MerkleTree.Proof.generateMerkleProof(tree, target_tx, tree.root.height, target_idx, length(tx_test))
    assert(proof.hash_values == merkle_path)
  end

  test "Successfully verifying a transaction", %{tx_test: tx_test, target_tx: target_tx, target_idx: target_idx, tx_count: tx_count, merkle_path: merkle_path} do
    tree = MerkleTree.makeMerkle(tx_test)
    proof = MerkleTree.Proof.generateMerkleProof(tree, target_tx, tree.root.height, target_idx, length(tx_test))
    assert(MerkleTree.Proof.verify_transaction(proof))
  end

  #TODO Should handle exception when trying to generate proof on faulty transaction.
  # test "Failing to verifying a transaction", %{tx_test: tx_test, target_tx: target_tx, target_idx: target_idx, tx_count: tx_count, merkle_path: merkle_path, target_tx_fail: target_tx_fail} do
  #   tree = MerkleTree.makeMerkle(tx_test)
  #   proof = MerkleTree.Proof.generateMerkleProof(tree, target_tx_fail, tree.root.height, target_idx, length(tx_test))
  #   assert(MerkleTree.Proof.verify_transaction(proof))
  # end

end
