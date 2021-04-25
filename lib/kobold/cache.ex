defmodule Kobold.Cache do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(%{cache_name: name, retry_after: retry_after}) do
    {:ok, %{name: name, retry_after: retry_after}}
  end

  def store_hash(hash, original) do
    GenServer.cast(__MODULE__, {:store, hash, original})
  end

  @impl true
  def handle_cast({:store, hash, original}, %{name: name, retry_after: retry_after} = state) do
    case Redix.command(name, ["SET", hash, original]) do
      {:ok, _} ->
        {:noreply, state}

      # If the Redis goes down before a reconnection can happen, attempt to insert later
      {:error, %Redix.ConnectionError{}} ->
        Process.send_after(__MODULE__, {:store, hash, original}, retry_after)
        {:noreply, state}

      {:error, %Redix.Error{}} ->
        Logger.error("failed to add #{hash} of #{original} to Redis cache")
        {:noreply, state}
    end
  end
end
