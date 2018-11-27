defmodule Crypto do
  @type hash256 :: <<_::256>>
  @type hash160 :: <<_::160>>
<<<<<<< HEAD

=======
  
>>>>>>> c897cd5874b3898b16c5a984e7e81f9250ce21a5
  def sha256(data), do: :crypto.hash(:sha256, data)
  def sha256x2(data), do: data |> sha256 |> sha256
  def ripemd160(data), do: :crypto.hash(:ripemd160, data)
end
