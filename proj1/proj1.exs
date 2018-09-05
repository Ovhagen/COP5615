params = Enum.map_every(System.argv, 1, fn(arg) -> String.to_integer(arg) end)
IO.inspect params

#Initialize input variables
endNbr = Enum.at(params, 0)
seqLen = Enum.at(params, 1)

#Create search space 1 -> N+k
searchSpace = Enum.to_list(1..endNbr)
#IO.inspect searchSpace
Proj1.calculate_seq(searchSpace, seqLen)