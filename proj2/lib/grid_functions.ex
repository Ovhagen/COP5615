defmodule GridFunctions do

  def check_distance(x1, y1, x2, y2, distance) do
    #if (calculate_distance(x1, y1, x2, y2) <= distance) == true do
      #IO.puts "true for {#{x1}, #{y1}} {#{x2},#{y2}}"
    #end
    calculate_distance(x1, y1, x2, y2) <= distance
  end

  def calculate_distance(x1, y1, x2, y2) do
    :math.sqrt(:math.pow((x2-x1), 2) + :math.pow((y2-y1), 2))
  end

  def random_double(precision) do
    :rand.uniform() |> Float.round(precision)
  end

end
