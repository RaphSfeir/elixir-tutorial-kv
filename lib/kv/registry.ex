defmodule KV.Registry do
  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name) 
  end

  @doc """
  Look up bucket pid for name stored in server, 

  Return {:ok, pid} if it exists
  :error if it doesn't
  """

  def lookup(server, name) when is_atom(server) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Be sure a bucket with name is in server
  """

  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  def stop(server) do
    GenServer.stop(server)
  end

  ##Server callbacks

  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = KV.Bucket.Supervisor.start_bucket
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs}}
    end  
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
