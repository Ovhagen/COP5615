defmodule Proj2.Topology do
  @moduledoc """
  Documentation for Proj2.Topology

  The functions in this module define various network topologies.
  Each function takes a list of nodes as input, and outputs a list of tuples in the form {node, neighbors}.
  """

  import GridFunctions


  @doc """
  Defines a fully-connected network, where each node is a neighbor of every other node.
  """
  def full(nodes) do
    Enum.map_reduce(nodes, tl(nodes), fn node, acc -> {{node, acc}, tl(acc) ++ [node]} end) |> elem(0)
  end


  @doc """
  Defines a randomized 2D-grid network, where neighbors are nodes within a distance of 0.1.
  """
  def grid_2d(nodes) do

    #The range for which a node is considered a neighbor
    range = 0.1

    #Maps on the form {node, {x,y}}
    nodeTuples = Enum.map(nodes,
    fn node -> {node, {random_double(2), random_double(2)}} end)

    #Recursively randomize neigbors
    nodeTuples = randomize_neighbors(hd(nodeTuples), nodeTuples, range, 0)

    #Maps on the form {node, {x,y}, otherNodes}
    nodeValues = Enum.map(nodeTuples, fn {node, val} -> {node, val, List.delete(nodeTuples, {node, val})} end)

    #Maps on the form {node, [{neighbors}]}
    nodeValues
    |> Enum.map(fn {node1, {x1,y1}, others} -> {node1, Enum.map(others, fn {node2, {x2,y2}} -> if check_distance(x1, y1, x2, y2, range) do node2 end end)
    |> Enum.filter(& !is_nil(&1))}
  end) |> List.flatten() #|> IO.inspect

  end

  ########### Helper functions grid_2d ############
  defp randomize_neighbors(_target_node, nodeTuples, _distance, index) when index == length(nodeTuples) do
    nodeTuples
  end

  @doc """
  Function for randomizing a 2D points for nodes, where neighbors are nodes within a certain distance.
  Returns a list of nodes that all have neighbors in the 2D grid.
  """
  defp randomize_neighbors(target_node, nodeTuples, distance, index) do
    {node, {x1, y1}} = target_node
    check = nodeTuples
      |> List.delete_at(index)
      |> Enum.any?(fn {_, {x2,y2}} -> check_distance(x1, y1, x2, y2, distance) end)
    if check == true do
      randomize_neighbors(Enum.at(nodeTuples, index+1), nodeTuples, distance, index+1)
    else
      #Update the node again and check for neighbors
      target_node = {node, {random_double(2), random_double(2)}}
      randomize_neighbors(target_node,
                          List.replace_at(nodeTuples, index, target_node),
                          distance,
                          index)
    end
  end


  @doc """
  Defines a 3D-grid network with interconnecting nodes.
  A block in the grid is 2x2x2 nodes.
  """
  def grid_3d(nodes) do
    order = 4
    #Maps on the form {node, neighbors}
    layers = nodes
    |> Enum.chunk_every(:math.pow(2, order) |> trunc())
    |> Enum.map(fn layer_nodes -> create_grid_layer(layer_nodes) end)

    #create_grid_layer
    #active_side, grid_nodes = nodes

    #nodes_left = nodes -- Enum.slice(nodes, 0..7)

    #IO.inspect grid_nodes

    #Enum.chunk_every(8,8)
  end


  defp create_grid_layer(nodes) do
    IO.puts "Initializing a grid"
    nodes
    |> Enum.chunk_every(4)
    |> Enum.map(fn chunk -> line(chunk) end)
    |> Enum.chunk_every(2, 1)
    #|> Enum.map(fn [[line1, line2]] -> Enum.map(line1,))

    # active_side =
    #   %{
    #     :left => {n3, y_len-1},
    #     :right => {n4, y_len-1},
    #     :upperright => {n7, y_len-1},
    #     :upperleft => {n8, y_len-1}
    #     #:topleft => {n5, 1},
    #     #:topright => {n6, 1}
    #     #:topupperright => {n7}
    #     #:topupperleft => {n8}
    #   }
    #
    # grid_nodes =
    #   [
    #     {n1, [n2, n4, n5]},
    #     {n2, [n1, n3, n6]},
    #     {n3, [n2, n4, n7]},
    #     {n4, [n1, n3, n8]},
    #     {n5, [n1, n6, n8]},
    #     {n6, [n2, n5, n7]},
    #     {n7, [n3, n6, n8]},
    #     {n8, [n4, n5, n7]}
    #   ]
    #
    #   {active_side, grid_nodes}
  end

  defp connect_nodes({node1, neighbors1}, {node2, neighbors2}) do
    [neighbors1 ++ node2, neighbors2 ++ node1]
  end

  @doc """
  Defines a linear-connected network, where each node has either one or two neighbors.
  """
  def line(nodes) do
    lastNode = [{Enum.at(nodes, length(nodes)-1), Enum.at(nodes, length(nodes)-2)}]

    Enum.zip(nodes, Enum.slice(nodes, 1, length(nodes)-1)) ++ lastNode
    |> Enum.zip(([nil] ++ Enum.slice(nodes, 0, length(nodes)-2) ++ [nil]))
    |> Enum.map(fn {{node, second}, first} -> {node, [first, second] |> Enum.filter(& !is_nil(&1))} end)
  end

  @doc """
  Defines a imperfect linear-connected network, where each node has one/two neighbors plus an extra random node.
  """
  def imperfect_line(nodes) do
    random_pool = nodes |> Enum.shuffle()
    line = line(nodes)
    im_line = randomize_recursive(List.first(line), 0, line, random_pool)
    IO.inspect im_line
    #Enum.map(fn {theLine, pool} -> fn -> {{node, neighbors}, _pool}
    #if length(random_pool) > 0 do {{node, neighbors ++ [Enum.random((pool -- (neighbors ++ [node])))]}, pool -- ([node] ++ [t])} else {node, neighbors} end end end)

    nodes_to_update = im_line |> Enum.map(fn {node, neighbors} -> List.last(neighbors) end)
    nodes_to_update2 = im_line |> Enum.map(fn {node, neighbors} -> {List.last(neighbors), node} end)
    IO.inspect im_line
    #IO.inspect nodes_to_update
    im_line |> Enum.map(fn {node, neighbors} -> if node in nodes_to_update do {node, neighbors ++ [Enum.find(nodes_to_update2, fn {to_update, _new_neighbor} -> to_update == node end) |> elem(1)]}#neighbors =
        #(neighbors ++ [Enum.find(nodes_to_update, fn {to_update, _new_neighbor} -> to_update == node end) |> elem(1)])
      else {node, neighbors} end end)
  end

  defp randomize_recursive(node, index, nodes, pool) when length(pool) == 0 do
    nodes
  end

  defp randomize_recursive(node, index, nodes, pool) do
    IO.inspect nodes
    IO.puts "Updating #{inspect(node)}"
    active_pool = pool -- ([node |> elem(0)] ++ (node |> elem(1)))
    randomNode = pool |> List.first()
    IO.puts "RandomNode #{inspect(randomNode)}"
    pool = pool |> List.delete(node |> elem(0))
    pool = pool |> List.delete(randomNode)
    IO.puts "New Pool #{inspect(pool)}"
    nodes = nodes |> List.update_at(index, fn {node, neighbors} -> {node, neighbors} = {node,neighbors ++ [randomNode]} end)
    randomize_recursive(Enum.at(nodes, index+1), index+1, nodes, pool
    )
  end

end
