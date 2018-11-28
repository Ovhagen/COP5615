# defmodule Proj4.MerkleProofTest do
#   use ExUnit.Case
#   @moduledoc """
#   This module defines a test for operations and functions in 'merkle_tree_proof.ex'.
#   """
#
#   setup do
#     %{
#     tx_test: ["c5246e478e0a319c099f94fe8e5b8c7b767a017f55408ebde477d0578659b4a8",
#                 "9ac0240b5e74ebaf38efa72e105cfeb06ee119dae56954dbd4f76cd790c738a5",
#                 "f25a13422d5cc7bb4331607502360cba53ceb6977623b3b4759fe96e42fdb1c8",
#                 "ce249be4a7f827ebccf51beb3d4cc919ee03b2aa51e4a3444142568d46a31a8a"],
#       target_tx: "c5246e478e0a319c099f94fe8e5b8c7b767a017f55408ebde477d0578659b4a8",
#       target_idx: 0,  #Given by target txs position in tx list
#       merkle_path: ["857d6e05018621948c70e1153562536144f41dd8adbe368280a9b4e27b794997",
#                    "161a1cc2a5cf1470f8abe426df4161c636be48cc0708e90ad712fa049bedab58",
#                    "4b468db712f4a9d2b14fa5bdf1d2149554cac6ee6d2b197fd4fa5560c56fa35c",
#                    "ffd2716e4f1f776214b3cd1713f2fa1b8714c775a1654a6ad6fe7372e5ee475a"],
#     target_tx_fail: "c5246e478e0a319c099f94fe8e5b8c7b767a017f55408ebde477d0578659b4a7"  #Changed one letter
# 	 }
#   end
#
#   @doc """
#   Test that the creation of a merkle proof is done correctly by comparing with the merkle path solution.
#   The answer was taken from hashes of the merkle tree nodes.
#   """
#   test "Use case when creating a proof object", %{tx_test: tx_test, target_tx: target_tx, target_idx: target_idx, merkle_path: merkle_path} do
#     tree = MerkleTree.makeMerkle(tx_test)
#     proof = MerkleTree.Proof.generateMerkleProof(tree, target_tx, tree.root.height, target_idx, length(tx_test))
#     assert(proof.hash_values == merkle_path)
#   end
#
#   @doc """
#   This test certifies that a transaction can be successfully verified to have been included in a block. The
#   verification process is carried out by hasing up the merkle path and finally compare with the merkle root.
#   """
#   test "Successfully verifying a transaction", %{tx_test: tx_test, target_tx: target_tx, target_idx: target_idx} do
#     tree = MerkleTree.makeMerkle(tx_test)
#     proof = MerkleTree.Proof.generateMerkleProof(tree, target_tx, tree.root.height, target_idx, length(tx_test))
#     assert(MerkleTree.Proof.verify_transaction(proof))
#   end
#
#   @doc """
#   This test certifies that a transaction can be successfully verified to have been included in a block. The
#   verification process is carried out by hasing up the merkle path and finally compare with the merkle root.
#   """
#   test "Failing to verifying a transaction", %{tx_test: tx_test, target_idx: target_idx, target_tx_fail: target_tx_fail} do
#     tree = MerkleTree.makeMerkle(tx_test)
#     assert_raise(MerkleTree.ProofError, fn () -> MerkleTree.Proof.generateMerkleProof(tree, target_tx_fail, tree.root.height, target_idx, length(tx_test)) end)
#   end
#
# end
