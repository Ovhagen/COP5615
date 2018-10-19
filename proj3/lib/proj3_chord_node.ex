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
  Starts a new Chord ring by kicking off the maintenance processes on a single node.
  Also can be used to restart a node that is simulating failure.
  """
  def start(n), do: GenServer.call(n, :start)

  @doc """
  Join n to an existing Chord c.
  """
  def join(n, c) when n != c, do: GenServer.call(n, {:join, c})

  @doc """
  Tell n to run the stabilize procedure, after a delay.
  """
  def stabilize(n), do: Process.send_after(n, :stabilize, delay(:st))

  @doc """
  Tell n that p might be its predecessor.
  """
  def notify(n, p), do: GenServer.cast(n, {:notify, p})

  @doc """
  Tell n to run the fix_fingers procedure, after a delay.
  """
  def fix_fingers(n), do: Process.send_after(n, :fix_fingers, delay(:ff))

  @doc """
  Tell n to run the check_predecessor procedure, after a delay.
  """
  def check_predecessor(n), do: Process.send_after(n, :check_predecessor, delay(:cp))
  
  @doc """
  FInd the first cycle starting at n. Used for testing network connectivity.
  """
  def cycle(n), do: GenServer.call(n, :cycle)

  @doc """
  Asks node n to find the successor of id.
  If successful returns a tuple with :ok, the pid of the successor, and the number of calls needed to complete the request.
  """
  def find_successor(n, id) when is_integer(id) do
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
  def find_successor(n, id), do: find_successor(n, get_id(id))
  
  @doc """
  Adds a key-value pair to the chord. Returns :ok if the pair is successfully added, :exists if the key already exists, and :error if the call fails.
  """
  def put(n, key, value) do
    case find_successor(n, get_id(key))
  
  @doc """
  Simulate a failure on n.
  """
  def failure(n), do: GenServer.call(n, :failure)
  
  ## Public utility functions
  
  # Retrieves environment configuration variables.
  def env(v), do: Application.get_env(:proj3, v)

  # Retreives the value of the :id_bits configuration parameter.
  def id_bits(), do: env(:id_bits)

  # Retreives the value of the :timeout configuration parameter.
  def timeout(), do: env(:timeout)
  
  # Retreives the value of the various delay configuration parameters.
  def delay(d), do: env(:delay)[d] |> :rand.normal(env(:jitter)) |> trunc()

  # Returns the modulus of the Chord ids, equal to 2^m where m is the number of id bits.
  def max_id(), do: 1 <<< id_bits()
  
  @doc """
  Generates a unique, random id by SHA hashing the input string and truncating to the configured bit length
  """
  def get_id(n), do: :crypto.hash(:sha, inspect(n)) |> Base.encode16() |> Integer.parse(16) |> elem(0) |> rem(max_id())

  ## Server Callbacks

  @doc """
  ChordNode initialization.
  Sets the id to the SHA-1 hash of the node's PID.
  """
  @impl true
  def init(_args) do
    pid = self()
    id = get_id(pid)
    # IO.puts "Child_Init: #{inspect(pid)} with id #{id}"
    {
      :ok,
      %{
        nid:         id,
        predecessor: nil,
        fingers:     List.duplicate(%{pid: pid, id: id}, id_bits()),
        next_finger: 0,
        data:        %{},
        failure:     :false
      }
    }
  end
  
  @doc """
  Used for starting a new single-node Chord, or restarting a node that is simulating failure.
  """
  @impl true
  def handle_call(:start, _from, state), do: {:reply, start(), Map.put(state, :failure, :false)}
  
  @doc """
  Used for simulating node failure.
  A :failure message will cause the node to begin ignoring all messages except :start.
  """
  def handle_call(:failure, _from, state), do: {:reply, :ok, Map.put(state, :failure, :true)}
  def handle_call(_msg, _from, %{failure: :true} = state), do: {:noreply, state}

  @doc """
  Used for joining an existing Chord ring.
  """
  def handle_call({:join, c}, _from, %{nid: nid} = state) do
    case find_successor(c, nid) do
      {:ok, s, _} ->
        fix_fingers(self())
        check_predecessor(self())
        {
          :reply,
          :ok,
          Map.update!(state, :fingers, &add_finger(&1, s, nid)),
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
    if between?(id, nid, hd(fingers)) do
      # Reply with successor
      # IO.puts "#{inspect(self())}: Successor of #{id} is #{inspect(hd(fingers))}"
      {:reply, {:ok, hd(fingers), 0}, state}
    else
      # Forward request along the chord
      {:noreply, state, {:continue, {:successor, from, id, 0}}}
    end
  end
  
  def handle_call(:cycle, from, %{nid: nid, fingers: [s | _]} = state) do
    GenServer.cast(s[:pid], {:cycle, from, [{self(), nid}]})
    {:noreply, state}
  end
  
  @doc """
  Ignores all casts when simulating node failure.
  """
  @impl true
  def handle_cast(_, %{failure: :true} = state), do: {:noreply, state}
  
  @doc """
  Handles forwarded find_successor requests.
  The forwarding node detects failures through a timer, so the timer is cancelled as soon as the cast is received.
  """
  def handle_cast({:successor, client, id, count, t}, %{nid: nid, fingers: fingers} = state) do
    Process.cancel_timer(t)
    if between?(id, nid, hd(fingers)) do
      # Reply to original client with successor
      # IO.puts "#{inspect(self())}: Successor of #{id} is #{inspect(hd(fingers))}"
      GenServer.reply(client, {:ok, hd(fingers), count})
      {:noreply, state}
    else
      # Forward request along the chord
      {:noreply, state, {:continue, {:successor, client, id, count}}}
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
    stabilize(self())
    fingers = if p, do: add_finger(fingers, p, nid), else: fingers
    notify(hd(fingers)[:pid], %{pid: self(), id: nid})
    {:noreply, Map.put(state, :fingers, fingers)}
  end
  
  @doc """
  Handles notifications from possible predecessors.
  The predecessor is updated if necessary, and the node is also checked against the finger table. This speeds up stabilization in new Chords.
  Continues to the :migrate procedure, which migrates data to the new predecessor if necessary.
  """
  def handle_cast({:notify, p}, %{nid: nid} = state) do
    {
      :noreply,
      state
        |> Map.update!(:predecessor, &(if !&1 || between?(p, &1, nid-1), do: p, else: &1))
        |> Map.update!(:fingers, &add_finger(&1, p, nid)),
      {:continue, :migrate}
    }
  end

  @doc """
  Handles replies from the fix_fingers Task.
  """
  def handle_cast({:fix_fingers, {:ok, f, _}}, %{nid: nid, next_finger: next} = state) do
    fix_fingers(self())
    {
      :noreply,
      state
        |> Map.put(:next_finger, next_finger?(f[:id], nid))
        |> Map.update!(:fingers, fn fs ->
             e = Enum.at(fs, next)
             # If the new finger is further than the old finger, then the old finger must have failed. Remove it first, then add the new finger.
             if not between?(f, nid, e), do: remove_finger(fs, e, nid), else: fs
               |> add_finger(f, nid)
           end)
    }
  end
  
  def handle_cast({:check, from, t}, state) do
    Process.cancel_timer(t)
    check_predecessor(from)
    {:noreply, state}
  end
  
  def handle_cast({:cycle, client, chain}, %{nid: nid, fingers: [s | _]} = state) do
    pair = {self(), nid}
    if pair in chain do
      GenServer.reply(client, Enum.reverse([pair] ++ chain))
    else
      GenServer.cast(s[:pid], {:cycle, client, [pair] ++ chain})
    end
    {:noreply, state}
  end
  
  @doc """
  Ignores all messages when simulating node failure.
  """
  @impl true
  def handle_info(_, %{failure: :true} = state), do: {:noreply, state}

  def handle_info(msg, state), do: {:noreply, state, {:continue, msg}}

  @doc """
  Handles forwarding of find_successor requests.
  If the recipient of the forwarded request fails to respond, the forward attempt is repeated with the next best predecessor.
  """
  @impl true
  def handle_continue({:successor, client, id, count} = request, %{nid: nid, fingers: fingers} = state) do
    # Find the closest predecessor in the finger table
    n = closest_preceding_node(fingers, id, nid)
    if n[:id] == nid do
      # We are the closest predecessor, so just reply to the client and do not forward the request. This should only happen if every other node has failed.
      GenServer.reply(client, {:ok, n, count})
      {:noreply, state}
    else
      # Forward the successor request to the best predecessor. Use a cast to avoid blocking, and set a timer for timeout.
      # IO.puts "#{inspect(self())}: Forwarding find_successor request to #{inspect(n[:pid])}"
      t = Process.send_after(self(), {:timeout, n, request}, timeout())
      GenServer.cast(n[:pid], {:successor, client, id, count+1, t})
      {:noreply, state}
    end
  end

  @doc """
  Handles stabilize requests.
  """
  def handle_continue(:stabilize, %{fingers: [s | _]} = state) do
    # IO.puts "#{inspect(self())}: Running stabilize, successor is #{inspect(s[:pid])}"
    t = Process.send_after(self(), {:timeout, s, :stabilize}, timeout())
    GenServer.cast(s[:pid], {:predecessor, self(), t})
    {:noreply, state}
  end

  @doc """
  Handles fix_fingers requests.
  This procedure requires a call to find_successor, so to avoid blocking the node it is called asynchronously through a Task.
  Once complete, the result is sent back to the node for handling.
  """
  def handle_continue(:fix_fingers, %{nid: nid, next_finger: next} = state) do
    pid = self()
    Task.start(fn ->
      s = find_successor(pid, nid + (1 <<< next) |> rem(max_id()))
      GenServer.cast(pid, {:fix_fingers, s})
    end)
    {:noreply, state}
  end
  
  def handle_continue(:check_predecessor, %{predecessor: p} = state) do
    if p do
      t = Process.send_after(self(), {:timeout, p, :check_predecessor}, timeout())
      GenServer.cast(p[:pid], {:check, self(), t})
    else
      check_predecessor(self())
    end
    {:noreply, state}
  end

  def handle_continue(:migrate, %{nid: nid, predecessor: p, data: data} = state) do
    keys = data
      |> Map.keys()
      |> Enum.filter(&between?(p, get_id(&1), nid))
    if length(keys) > 0 do
      {:ok, keys} = GenServer.call(p[:pid], {:migrate, Map.take(data, keys)})
      {:noreply, Map.put(state, :data, Map.take(data, Map.keys(data) -- keys))}
    else
      {:noreply, state}
    end
  end

  def handle_continue({:timeout, n, request}, %{nid: nid} = state) do
    IO.puts "#{inspect(self())}: Timed out on request #{inspect(request)} to #{inspect(n[:pid])}"
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
  
  # Returns true if id is in the interval (n, s]. Otherwise returns false.
  # For convenience, you can pass a pid or a map containing an :id key for any of the parameters.
  defp between?(id, n, s) when is_pid(id), do: between?(get_id(id), n, s)
  defp between?(id, n, s) when is_pid(n),  do: between?(id, get_id(n), s)
  defp between?(id, n, s) when is_pid(s),  do: between?(id, n, get_id(s))
  defp between?(id, n, s) when is_map(id), do: between?(id[:id], n, s)
  defp between?(id, n, s) when is_map(n),  do: between?(id, n[:id], s)
  defp between?(id, n, s) when is_map(s),  do: between?(id, n, s[:id])
  defp between?(id, n, s) when n >= s do
    between?(id, n, max_id()-1)
      or between?(id, -1, s)
  end
  defp between?(id, n, s), do: id > n and id <= s
  
  # Kicks off the node maintenance processes.
  defp start() do
    stabilize(self())
    fix_fingers(self())
    check_predecessor(self())
    :ok
  end

  # Searches fingers for the furthest node that precedes the id
  defp closest_preceding_node(fingers, id, nid) do
    Enum.reverse(fingers)
      |> Enum.reduce_while(%{pid: self(), id: nid}, fn n, f ->
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
  def add_finger(fingers, n, nid) do
    Enum.map_reduce(fingers, 1, fn f, acc ->
      if between?(n, rem(nid+acc, max_id()), f) do
        {n, acc*2}
      else
        {f, acc*2}
      end
    end)
      |> elem(0)
  end

  # Removes a node from the finger table, replacing all occurrences with its next known successor.
  def remove_finger(fingers, n, nid) do
    fingers
      |> Enum.reverse()
      |> Enum.map_reduce(%{pid: self(), id: nid}, &(if &1 == n, do: {&2, &2}, else: {&1, &1}))
      |> elem(0)
      |> Enum.reverse()
  end
end
