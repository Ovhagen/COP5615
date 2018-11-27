defmodule Block do
  @moduledoc """
  This module defines a full block in the bitcoin protocol. Blocks are
  created by miners. Full nodes in the network will store whole blocks.

  The member Magic number is omitted in this implementation.
  """
  import Crypto
  
  @version 1
  
  defmodule Header do
    defstruct version: @version, previous_hash: <<>>, merkle_root: <<>>, timestamp: 0, target: <<>>, nonce: 0

    @type t :: %Header{
        version: non_neg_integer,
        previous_hash: Crypto.hash256,
        merkle_root: Crypto.hash256,
        timestamp: non_neg_integer,
        target: <<_::32>>,
        nonce: non_neg_integer
    }
    
    @doc """
    Generates a block hash by serializing the header and double hashing it.
    """
    @spec block_hash(t) :: Crypto.hash256
    def block_hash(header), do: serialize(header) |> sha256x2
    
    def serialize(%Header{version: v, previous_hash: p, merkle_root: m, timestamp: t, target: g, nonce: n}) do
      <<v::32>> <> p <> m <> <<t::32>> <> g <> <<n::32>>
    end
    
    def deserialize(<<v::32, p::binary-32, m::binary-32, t::32, g::binary-4, n::32>>) do
      %Header{
        version: v,
        previous_hash: p,
        merkle_root: m,
        timestamp: t,
        target: g,
        nonce: n
      }
    end
  end

  defstruct block_size: 0, block_header: %Header{}, tx_counter: 0, transactions: []

  @type t :: %Block{
      block_size: block_size,
      block_header: block_header,
      tx_counter: tx_counter,
      transactions: transactions
  }
  
  @doc """
  Calculates the difficulty target from the 4-byte representation in the block header.
  """
  @spec calc_target(<<_::32>>) :: non_neg_integer
  def calc_target(<<e::8, c::24>>), do: c <<< (8 * (e - 3))

  @doc """
  This function creates a block. In the bitcoin protocol
  blocks are explicitly created by miners. A block will then
  be accepted into the new chain if the block hash is validated
  by the rest of the network.
  """
  @spec build_block([String.t, ...], String.t, String.t, non_neg_integer) :: Block.t
  def createBlock(transactions, merkle_root, prev_hash, nonce) do
    block_header = %Block.BlockHeader{
      version: Application.get_env(:proj4, :block_version),
      previous_hash: List.to_string(prev_hash),
      merkle_root: merkle_root,
      timestamp: Application.get_env(:proj4, :timestamp),#:os.system_time(:seconds),
      difficulty: Application.get_env(:proj4, :block_difficulty),
      nonce: nonce
    }
    tx_counter = length(transactions)
    tx_size = transactions |> Enum.map(&(byte_size(&1))) |> Enum.sum()
    block_size = calculate_header_size(block_header) + integer_size(tx_counter) + tx_size
    %Block{
      block_size: block_size,
      block_header: block_header,
      tx_counter: tx_counter,
      transactions: transactions
    }
  end

  @doc """
  A function which verifies a block. This is done by computing the block hash with
  the nonce and compare with the provided block hash as well as comparing to set difficulty.
  Additionally, the merkle root is calculated for all the transactions included in the block
  and compared with. This functionality will mainly be used by full nodes in the network,
  namely miners. Caller can specify how many criterias are of interest for verification.
  A full node or miner would check all conditions.
  """
  @spec verifyBlock(Block.t, BLock.BlockHeader.t, String.t) :: Boolean.t
  def verifyBlock(block \\ nil, header, response_hash, mode \\ [:diff, :block, :merkle]) do
    if Enum.member?(mode, :diff) do
      difficulty = header.difficulty |> endian_converter() |> String.pad_trailing(64, "0")
      unless response_hash |> String.to_integer(16) <= difficulty |> String.to_integer(16), do: raise Block.DiffError
    end

    if Enum.member?(mode, :block) do
      calculated_hash = generate_block_hash(header)
      unless calculated_hash == response_hash, do: raise Block.BlockHashError
    end

    if Enum.member?(mode, :merkle) && block != nil do
      tree = MerkleTree.makeMerkle(block.transactions)
      unless tree.root.hash_value == header.merkle_root, do: raise Block.MerkleRootError
    end
    true
  end

end
