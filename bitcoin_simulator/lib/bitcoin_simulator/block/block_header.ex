defmodule Block.Header do
  import Crypto
  
  @version 1

  defstruct version: @version, previous_hash: <<>>, merkle_root: <<>>, timestamp: 0, target: <<>>, nonce: 0

  @type t :: %Block.Header{
    version: non_neg_integer,
    previous_hash: Crypto.hash256,
    merkle_root: Crypto.hash256,
    timestamp: DateTime.t,
    target: <<_::32>>,
    nonce: non_neg_integer
  }

  def new(previous_hash, merkle_root, target, nonce \\ 0) do
    %Block.Header{
      version: @version,
      previous_hash: previous_hash,
      merkle_root: merkle_root,
      timestamp: DateTime.utc_now |> DateTime.truncate(:second),
      target: target,
      nonce: nonce
    }
  end

  @doc """
  Generates a block hash by serializing the header and double hashing it.
  """
  @spec hash(t) :: Crypto.hash256
  def hash(header), do: serialize(header) |> sha256x2

  def serialize(%Block.Header{version: v, previous_hash: p, merkle_root: m, timestamp: t, target: g, nonce: n}) do
    <<v::32>> <> p <> m <> <<DateTime.to_unix(t)::32>> <> g <> <<n::32>>
  end

  def deserialize(<<v::32, p::binary-32, m::binary-32, t::32, g::binary-4, n::32>>) do
    %Block.Header{
      version:       v,
      previous_hash: p,
      merkle_root:   m,
      timestamp:     DateTime.from_unix!(t),
      target:        g,
      nonce:         n
    }
  end

  def bytes(), do: 80
end
