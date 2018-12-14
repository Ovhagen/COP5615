defmodule BitcoinSimulator do
  @moduledoc """
  Helper functions for the simulation.
  """
  
  @doc """
  This function generates transactions randomly in order to simulate traffic on the network.
  """
  def tx_generator(wallets, freq) do
    [payor, payee] = Enum.take_random(wallets, 2)
    {:ok, balance} = Bitcoin.Wallet.get_balance(payor)
    if balance > 0 do
      value = (balance*0.75) |> trunc |> :rand.uniform |> Kernel.+(balance*0.05) |> trunc
      with :ok <- Bitcoin.Wallet.request_payment(payor, value, Bitcoin.Wallet.get_pkh(payee) |> elem(1)) do
        Process.sleep(min(trunc(1000/freq), 1))
      end
    end
    tx_generator(wallets, freq)
  end
end
