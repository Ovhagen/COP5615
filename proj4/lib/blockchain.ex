defmodule Blockchain do
  import Crypto

  @coin 1_000_000

  defmodule UTXO do
    @type id :: <<_::264>>
    @type t :: %{required(id) => Transaction.Vout.t}

    @spec id(Transaction.t, non_neg_integer) :: id
    def id(tx, vout), do: Transaction.hash(tx) <> <<vout::8>>
    @spec id(Transaction.Vin.t) :: id
    def id(vin), do: vin.txid <> <<vin.vout::8>>

    @spec delete(t, Transaction.Vin.t | [Transaction.Vin.t, ...]) :: t
    def delete(utxo, [vin | tail]), do: delete(utxo, vin) |> delete(tail)
    def delete(utxo, []), do: utxo
    def delete(utxo, vin), do: Map.delete(utxo, id(vin))
  end

  defmodule Mempool do
    defstruct tx: %Transaction{}, fee: 0
    @type t :: %{required(Crypto.hash256) => %Mempool{}}

    @spec insert(t, Transaction.t, non_neg_integer) :: t
    def insert(mempool, tx, fee), do: Map.put(mempool, Transaction.hash(tx), %Mempool{tx: tx, fee: fee})
  end

  defstruct tip: %Blockchain.Link{}, utxo: %{}, mempool: %{}

  @type t :: %Blockchain{}

  @spec verify_tx(t, Transaction.t) :: {:ok, non_neg_integer} | {:error, atom}
  def verify_tx(bc, tx) do
    with true        <- Transaction.verify(tx),
         {:ok, vout} <- get_utxo(bc.utxo, tx.vin),
         :ok         <- verify_pkh(vout, tx.vin),
         fee         <- Transaction.fee(vout, tx.vout)
    do
      if fee > 0, do: {:ok, fee}, else: {:error, :fee}
    else
      false           -> {:error, :sig}
      {:error, error} -> {:error, error}
    end
  end

  def get_utxo(utxo, vin) do
    Enum.reduce_while(vin, {:ok, []}, fn vin, {:ok, acc} ->
      case Map.fetch(utxo, vin.txid <> <<vin.vout::8>>) do
        {:ok, vout} -> {:cont, {:ok, acc ++ [vout]}}
        :error      -> {:halt, {:error, :utxo}}
      end
    end)
  end

  def verify_pkh(vout, vin) do
    Enum.zip(vout, vin)
    |> Enum.reduce_while(:ok, fn {vo, vi}, valid ->
         if vo.pkh == KeyAddress.pubkey_to_pkh(vi.witness.pubkey) do
           {:cont, :ok}
         else
           {:halt, {:error, :pkh}}
         end
       end)
  end

  @spec add_to_mempool(t, Transaction.t) :: {:ok, t} | :error
  def add_to_mempool(bc, tx) do
    with {:ok, fee} <- verify_tx(bc, tx) do
      {
        :ok,
        Map.update!(bc, :utxo, &UTXO.delete(&1, tx.vin))
          |> Map.update!(:mempool, &Mempool.insert(&1, tx, fee))
      }
    else
      error -> error
    end
  end

  def verify_block(bc, block) do
    # 1. Block is internally valid (merkle root and hash value)
    # 2. Block points to tip of current blockchain
    # 3. Difficulty target is correct
    # 4. All transactions are in the mempool
    # 5. Coinbase transaction is correct (structure, fees and reward correct)
    with :ok <- Block.verify(block),
         :ok <- verify_tip(bc, block),
         :ok <- verify_target(bc, block),
         :ok <- verify_mempool(bc, block),
         :ok <- verify_coinbase(bc, block)
    do
      :ok
    else
      error -> error
    end
  end

  def verify_tip(bc, block) do
    if block.header.prev == bc.tip.hash, do: :ok, else: {:error, :tip}
  end

  def verify_target(bc, block) do
    if block.header.target == next_target(bc), do: :ok, else: {:error, :target}
  end

  def verify_mempool(bc, block) do
    Enum.reduce_while(block.transactions, :ok, fn tx, :ok ->
      if Transaction.hash(tx) in bc.mempool, do: {:cont, :ok}, else: {:halt, {:error, :mempool}} end)
  end

  def verify_coinbase(bc, block) do
    # need to figure out coinbase transactions
  end

  @spec block_subsidy(t) :: non_neg_integer
  def block_subsidy(bc) do
    50 * @coin # constant block reward for now
  end

  @spec next_target(t) :: <<_::32>>
  def next_target(bc) do
    bc.tip.block.header.target # Just keep previous difficulty
  end

  def genesis() do
    # Returns a new blockchain starting from the hard-coded genesis block
  end
end
