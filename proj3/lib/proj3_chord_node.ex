defmodule Proj3.ChordNode do
  @moduledoc """

  """
  use GenServer
  import Bitwise

  ## Client API

  @doc """
  Starting and linking the GenServer process.
  node_hash: The hash of the node.
  fingers: Local routing table of the node. A finger consists is {hash, pid}.
  predecessor: Reference to the previous node in the chord ring. (just the hash?)
  data: A hash table with data stored at the node.
  """
  def start_link([]), do: GenServer.start_link(__MODULE__, [])

  @doc """
  Join n to an existing Chord c.
  
  The sequence of events is as follows:
    1. Find the successor of c.
    2. Place the successor in the first entry of c's finger table.
    3. Run stabilize on c, which should result in notifying c's successor.
    4. c's successor receives the notification and responds by attempting to migrate keys.
    5. Run fix_fingers on c.
  """
  def join(n, c) when n != c, do: GenServer.call(n, {:join, c})

  def stabilize(n), do: send(n, :stabilize)

  @doc """
  Tell n that p might be its predecessor.
  """
  def notify(n, p), do: GenServer.cast(n, {:notify, p})
  
  def fix_fingers(n), do: send(n, :fix_fingers)

  def check_predecessor(n), do: send(n, :check_predecessor)

  @doc """
  Asks node n to find the successor of id.
  If successful returns a tuple with :ok, the pid of the successor, and the number of calls needed to complete the request.
  """
  def find_successor(n, id) do
    if get_id(n) == id do
      {:ok, {n, id}, 0}
    else
      try do
        GenServer.call(n, {:successor, id})
      catch
        :exit, _ -> {:error, "Call failed: no response from node"}
      end
    end
  end

  ## Server Callbacks

  @doc """
  ChordNode initialization.
  Sets the id to the SHA-1 hash of the node's PID.
  """
  @impl true
  def init(_args) do
    pid = self()
    id = get_id(pid)
    IO.puts "Child_Init: #{inspect(pid)} with id #{id}"
    {
      :ok,
      %{
        nid: id,
        predecessor: nil,
        fingers: List.duplicate(%{pid: pid, id: id}, id_bits()),
        next_finger: 0,
        data: %{}
      }
    }
  end
  
  @impl true
  def handle_call({:join, c}, _from, %{nid: nid} = state) do
    case find_successor(c, nid) do
      {:ok, s, _} ->
        fix_fingers(self())
        check_predecessor(self())
        {
          :reply,
          :ok,
          Map.update!(state, :fingers, &([s] ++ tl(&1))),
          {:continue, :stabilize}
        }
      {:error, _} ->
        # The node did not respond, so the join failed
        {:reply, {:error, "Join failed: no response from node"}, state}
    end
  end
  
  def handle_call({:migrate, new_data}, _from, state) do
    {
      :reply,
      Map.keys(new_data),
      Map.update!(state, :data, &Map.merge(&1, new_data))
    }
  end

  @doc """
  Handles call for find_successor.
  This handler is used for calls coming directly from the client, and responds directly if the successor is found immediately. Forwarded requests are handled as casts.
  This structure allows the call to proceed without blocking every node along the path, and ensures that timeouts due to failed nodes are caught correctly.
  Since both versions may need to forward a request, that code is moved into a :continue handler.
  """
  def handle_call({:successor, id}, from, %{nid: nid, fingers: fingers} = state) do
    if between?(id, nid, get_in(hd(fingers), :id)) do
      # Reply with successor
      {:reply, {:ok, hd(fingers), 0}, state}
    else
      # Forward request along the chord
      {:noreply, state, {:continue, {:successor, from, id, 0}}}
    end
  end
  
  @doc """
  Handles forwarded find_successor requests.
  The forwarding node detects failures through a timer, so the timer is cancelled as soon as the cast is received.
  """
  @impl true
  def handle_cast({:successor, client, id, count, t}, %{nid: nid, fingers: fingers} = state) do
    Process.cancel_timer(t)
    if between?(id, nid, get_in(hd(fingers), :id)) do
      # Reply to original client with successor
      GenServer.reply(client, {:ok, hd(fingers), count})
      {:reply, :ok, state}
    else
      # Forward request along the chord
      {:reply, :ok, state, {:continue, {:successor, client, id, count}}}
    end
  end
  
  @doc """
  Handles predecessor requests. This only occurs during stabilization, so the response is labeled accordingly.
  Failures are detected through a timer, so the timer is cancelled upon receipt.
  """
  def handle_cast({:predecessor, from, t}, %{predecessor: p} = state) do
    Process.cancel_timer(t)
    GenServer.cast(from, {:stabilize, p})
    {:noreply, state}
  end
  
  @doc """
  Handles predecessor responses during stabilization.
  Adding the node to the finger table will automatically place it in the successor location if that is where it belongs.
  """
  def handle_cast({:stabilize, p}, %{nid: nid, fingers: fingers} = state) do
    Process.send_after(self(), :stabilize, Application.get_env(:proj3, :st_delay))
    fingers = add_finger(fingers, p, nid)
    notify(get_in(hd(fingers), :pid), %{pid: self(), id: nid})
    {:noreply, Map.put(state, :fingers, fingers)}
  end
  
  def handle_cast({:notify, p}, %{nid: nid, predecessor: q} = state) do
    if q and between?(p, q, nid-1) do
      {
        :noreply,
        Map.put(state, :predecessor, p),
        {:continue, :migrate}
      }
    else
      {:noreply, state}
    end
  end
  
  @doc """
  Handles replies from the fix_fingers Task.
  """
  def handle_cast({:fix_fingers, {:ok, f, _}}, %{nid: nid, next_finger: next} = state) do
    Process.send_after(self(), :fix_fingers, Application.get_env(:proj3, :ff_delay))
    {
      :noreply,
      state
        |> Map.put(:next_finger, next_finger?(get_in(f, :id), nid))
        |> Map.update!(:fingers, fn fs ->
             e = Enum.at(fs, next)
             # If the new finger is further than the old finger, then the old finger must have failed. Remove it first, then add the new finger.
             if between?(e, nid, f), do: remove_finger(fs, e, nid), else: fs
               |> add_finger(f, nid)
           end)
    }
  end
  
  def handle_cast({:check, t}, state) do
    Process.cancel_timer(t)
    {:noreply, state}
  end
  
  @impl true
  def handle_info(msg, state), do: {:noreply, state, {:continue, msg}}

  @doc """
  Handles forwarding of find_successor requests.
  If the recipient of the forwarded request fails to respond, the forward attempt is repeated with the next best predecessor.
  """
  @impl true
  def handle_continue({:successor, client, id, count} = request, %{nid: nid, fingers: fingers} = state) do
    # Find the closest predecessor in the finger table
    n = closest_preceding_node(fingers, id, nid)
    if get_in(n, :id) == nid do
      # We are the closest predecessor, so just reply to the client and do not forward the request. This should only happen if every other node has failed.
      GenServer.reply(client, {:ok, n, count})
      {:noreply, state}
    else
      # Forward the successor request to the best predecessor. Use a cast to avoid blocking, and set a timer for timeout.
      t = Process.send_after(self(), {:timeout, n, request}, timeout())
      GenServer.cast(get_in(n, :pid), {:successor, client, id, count+1, t})
      {:noreply, state}
    end
  end
  
  @doc """
  Handles stabilize requests.
  """
  def handle_continue(:stabilize, %{fingers: [s | _]} = state) do
    t = Process.send_after(self(), {:timeout, s, :stabilize}, timeout())
    GenServer.cast(get_in(s, :pid), {:predecessor, self(), t})
    {:noreply, state}
  end
  
  @doc """
  Handles fix_fingers requests.
  This procedure requires a call to find_successor, so to avoid blocking the node it is called asynchronously through a Task.
  Once complete, the result is sent back to the node for handling.
  """
  def handle_continue(:fix_fingers, %{nid: nid, next_finger: next} = state) do
    Task.start(fn ->
      GenServer.cast(self(), {:fix_fingers, find_successor(self(), :math.pow(2, next) |> Kernel.+(nid) |> rem(max_id()))})
    end)
    {:noreply, state}
  end
  
  def handle_continue(:check_predecessor, %{predecessor: p} = state) do
    if p do
      t = Process.send_after(self(), {:timeout, p, :check_predecessor}, timeout())
      GenServer.cast(get_in(p, :pid), {:check, t})
    else
      Process.send_after(self(), :check_predecessor, Application.get_env(:proj3, :cp_delay))
    end
    {:noreply, state}
  end
  
  def handle_continue(:migrate, %{nid: nid, predecessor: p, data: data} = state) do
    keys = data
      |> Map.keys()
      |> Enum.filter(&between?(p, get_id(&1), nid))
    if length(keys) > 0 do
      {:ok, keys} = GenServer.call(get_in(p, :pid), {:migrate, Map.take(data, keys)})
      {:noreply, Map.put(state, :data, Map.take(data, Map.keys(data) -- keys))}
    else
      {:noreply, state}
    end
  end
  
  def handle_continue({:timeout, n, request}, %{nid: nid} = state) do
    {
      :noreply,
      state
        |> Map.update!(:fingers, &remove_finger(&1, n, nid))
        |> Map.update!(:predecessor, &(if n == &1, do: nil, else: &1)),
      {:continue, request}
    }
  end
  
  # Ignore unexpected messages
  def handle_continue(_, state), do: {:noreply, state}
  
  ## Private implementation functions
  
  # Retreives the value of the :id_bits configuration parameter.
  defp id_bits(), do: Application.get_env(:proj3, :id_bits)
  
  # Retreives the value of the :timeout configuration parameter.
  defp timeout(), do: Application.get_env(:proj3, :timeout)
  
  # Returns the modulus of the Chord ids, equal to 2^m where m is the number of id bits.
  defp max_id(), do: 1 <<< id_bits()
  
  # Returns true if id is in the interval (n, s]. Otherwise returns false.
  # For convenience, you can pass a pid or a map containing an :id key for any of the parameters.
  defp between?(id, n, s) when is_pid(id), do: between?(get_id(id), n, s)
  defp between?(id, n, s) when is_pid(n),  do: between?(id, get_id(n), s)
  defp between?(id, n, s) when is_pid(s),  do: between?(id, n, get_id(s))
  defp between?(id, n, s) when is_map(id), do: between?(get_in(id, :id), n, s)
  defp between?(id, n, s) when is_map(n),  do: between?(id, get_in(n, :id), s)
  defp between?(id, n, s) when is_map(s),  do: between?(id, n, get_in(s, :id))
  defp between?(id, n, s) when n >= s do
    between?(id, n, max_id()-1)
      or between?(id, -1, s)
  end
  defp between?(id, n, s), do: id > n and id <= s

  # Generates a unique, random id by SHA hashing the input string and truncating to the configured bit length
  defp get_id(n) do
    :crypto.hash(:sha, inspect(n))
      |> Base.encode16()
      |> Integer.parse(16)
      |> elem(0)
      |> rem(max_id())
  end

  # Searches fingers for the furthest node that precedes the id
  defp closest_preceding_node(fingers, id, nid) do
    Enum.reverse(fingers)
      |> Enum.reduce_while(self(), fn n, f ->
           if between?(n, nid, id-1) do
             {:halt, n}
           else
             {:cont, f}
           end end)
  end
  
  # Determines the next finger to check, based on the id of the last finger found.
  defp next_finger?(fid, nid), do: fid-nid+max_id()+1 |> rem(max_id()) |> :math.log2() |> Float.ceil() |> trunc() |> rem(id_bits())
  
  # Updates the finger table with a new node.
  # Replaces each entry of the table where n is a closer successor than the existing finger.
  defp add_finger(fingers, n, nid) do
    Enum.map_reduce(fingers, 1, fn f, acc ->
      if between?(n, rem(nid+acc, max_id()), f) do
        {n, acc*2}
      else
        {f, acc*2}
      end
    end)
  end
  
  # Removes a node from the finger table, replacing all occurrences with its next known successor.
  defp remove_finger(fingers, n, nid) do
    fingers
      |> Enum.reverse()
      |> Enum.map_reduce(%{pid: self(), id: nid}, &(if &1 == n, do: {&2, &2}, else: {&1, &1}))
      |> elem(0)
  end
end
