defmodule Proj2.GossipNodeTest do
  use ExUnit.Case
  
  setup do
    tx_fn =   fn x -> {x, 1} end
	rcv_fn =  fn x, y -> x+y end
	mode_fn = fn x -> if x < 10, do: {:ok, x}, else: {:kill, x} end
	nodes = [:node1, :node2, :node3]
	  |> Enum.map(fn node ->
	       %{id: node,
		     start: {
			   Proj2.GossipNode,
			   :start_link,
			   [%{mode:      :passive,
			      data:      0,
				  neighbors: [],
				  tx_fn:     tx_fn,
				  rcv_fn:    rcv_fn,
				  mode_fn:   mode_fn
			   }]
			 }
		   } end)
      |> Enum.map(fn node -> start_supervised!(node) end)
    %{
	  nodes: nodes
	}
  end
  
  test "update neighbors", %{nodes: [node1, node2, node3]} do
    :ok = Proj2.GossipNode.update(node1, :neighbors, fn _x -> [node2, node3] end)
	assert Proj2.GossipNode.get(node1, :neighbors) == [node2, node3]
	:ok = Proj2.GossipNode.update(node2, :neighbors, fn _x -> [node1, node3] end)
	:ok = Proj2.GossipNode.update(node3, :neighbors, fn _x -> [node1, node2] end)
  end
end