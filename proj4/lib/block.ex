defmodule Block do
  @moduledoc """
  This module defines a full block in the bitcoin protocol. Blocks are
  created by miners. Full nodes in the network will store whole blocks.
  """
  import Crypto
  
  @version 1
  
  defmodule Header do
    defstruct version: @version, previous_hash: <<>>, merkle_root: <<>>, timestamp: 0, target: <<>>, nonce: 0

    @type t :: %Header{
      version: non_neg_integer,
      previous_hash: Crypto.hash256,
      merkle_root: Crypto.hash256,
      timestamp: DateTime.t,
      target: <<_::32>>,
      nonce: non_neg_integer
    }
    
    def new(previous_hash, merkle_root, target, nonce \\ 0) do
      %Header{
        version: @version,
        previous_hash: previous_hash,
        merkle_root: merkle_root,
        timestamp: DateTime.utc_now,
        target: target,
        nonce: nonce
      }
    end
    
    @doc """
    Generates a block hash by serializing the header and double hashing it.
    """
    @spec block_hash(t) :: Crypto.hash256
    def block_hash(header), do: serialize(header) |> sha256x2
    
    def serialize(%Header{version: v, previous_hash: p, merkle_root: m, timestamp: t, target: g, nonce: n}) do
      <<v::32>> <> p <> m <> <<DateTime.to_unix(t)::32>> <> g <> <<n::32>>
    end
    
    def deserialize(<<v::32, p::binary-32, m::binary-32, t::32, g::binary-4, n::32>>) do
      %Header{
        version:       v,
        previous_hash: p,
        merkle_root:   m,
        timestamp:     DateTime.from_unix(t),
        target:        g,
        nonce:         n
      }
    end
    
    def bytes(), do: 80
  end

  defstruct bytes: 0, header: %Header{}, tx_counter: 0, transactions: [], merkle_tree: %MerkleTree{}

  @type t :: %Block{
    bytes:        non_neg_integer,
    header:       Header.t,
    tx_counter:   non_neg_integer,
    transactions: [Transaction.t, ...],
    merkle_tree:  MerkleTree.t
  }
  
  def new(transactions, previous_hash, target, nonce \\ 0) do
    merkle_tree = MerkleTree.build_tree(transactions)
    %Block{
      bytes:        4 * (length(transactions) + 1) + Header.bytes + Enum.reduce(transactions, 0, &(&2 + Transaction.bytes(&1))),
      header:       Header.new(previous_hash, merkle_tree.root.hash, target, nonce),
      tx_counter:   length(transactions),
      transactions: transactions,
      merkle_tree:  merkle_tree
    }
  end
  
  @doc """
  Verifies that a block is internally consistent by checking the version number, timestamp, merkle root, and header hash.
  This does NOT verify that a block is valid within a specific blockchain, only that it has been constructed correctly.
  """
  @spec verify(t) :: boolean
  def verify(%Block{} = block) do
    verify_version(block)
      and verify_timestamp(block)
      and verify_merkle(block)
      and verify_hash(block)
  end
  defp verify_version(block), do: block.version == @version
  defp verify_timestamp(block), do: DateTime.diff(DateTime.utc_now, block.timestamp) > 7200
  defp verify_merkle(block), do: block.merkle_tree.root.hash == block.header.merkle_root
  defp verify_hash, do: Header.block_hash(header) < calc_target(block.header.target)
  
  def serialize(%Block{} = block) do
    Header.serialize(block.header)
      <> <<block.tx_counter::32>>
      <> Enum.reduce(Enum.reverse(block.transactions), <<>>, fn tx, acc ->
           bytes = Transaction.bytes(tx)
           <<bytes::32>> <> Transaction.serialize(tx) <> acc
         end)
  end
  
  def deserialize(data)
  
  @doc """
  Calculates the difficulty target from the 4-byte representation in the block header.
  """
  @spec calc_target(<<_::32>>) :: non_neg_integer
  def calc_target(<<e::8, c::24>>), do: c <<< (8 * (e - 3))
end