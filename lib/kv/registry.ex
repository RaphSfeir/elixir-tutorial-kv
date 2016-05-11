defmodule KV.Registry do
  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Look up bucket pid for name stored in server, 

  Return {:ok, pid} if it exists
  :error if it doesn't
  """

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Be sure a bucket with name is in server
  """

  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ##Server callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link
      {:noreply, Map.put(names, name, bucket)}
    end  
  end
end
