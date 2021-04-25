defmodule Kobold.Cache do
  # TODO: Add elaborate fail safe feature similar to the rate limiting feature of Broadway to monitor Redis connections
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(cache_name: name, retry_after: retry_after) do
    {:ok, %{name: name, retry_after: retry_after}}
  end

  def store_hash(hash, original) do
    GenServer.cast(__MODULE__, {:store, hash, original})
  end

  def has_hash?(hash) do
    GenServer.call(__MODULE__, {:has_hash?, hash})
  end

  @impl true
  def handle_cast({:store, hash, original}, %{name: name, retry_after: retry_after} = state) do
    case Redix.command(name, ["SET", hash, original]) do
      {:ok, _} ->
        Logger.info("storing #{hash} of #{original} to Redis cache")
        {:noreply, state}

      # If the Redis goes down before a reconnection can happen, attempt to insert later
      {:error, %Redix.ConnectionError{}} ->
        Logger.warning(
          "unable to add #{hash} of #{original} to Redis cache due to connection error, re-attempting in #{
            retry_after / 1_000
          }s"
        )

        Process.send_after(__MODULE__, {:store, hash, original}, retry_after)
        {:noreply, state}

      {:error, %Redix.Error{message: message}} ->
        Logger.error(
          "failed to add #{hash} of #{original} to Redis cache with message #{message}"
        )

        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:has_hash?, hash}, _from, %{name: name, retry_after: retry_after} = state) do
    case Redix.command(name, ["GET", hash]) do
      {:ok, original} ->
        if !is_nil(original) do
          Logger.info("#{hash} of #{original} found")
        else
          Logger.info("#{hash} not found in cache")
        end

        {:reply, !is_nil(original), state}

      {:error, %Redix.ConnectionError{}} ->
        Logger.warning(
          "unable to get #{hash} from Redis cache due to connection error, re-attempting in #{
            retry_after / 1_000
          }s"
        )

        Process.send_after(__MODULE__, {:get_hash, hash}, retry_after)
        {:reply, false, state}

      {:error, %Redix.Error{message: message}} ->
        Logger.error("failed to get #{hash} from Redis with message #{message}")
        {:reply, false, state}
    end
  end
end
