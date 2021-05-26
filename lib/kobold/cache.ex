defmodule Kobold.Cache do
  # TODO: Add elaborate fail safe feature similar to the rate limiting feature of Broadway to monitor Redis connections
  # TODO: Simply repeated code
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(cache_name: name, retry_after: retry_after) do
    events = [:get, :set, :delete]
    status = [:success, :connection_error, :redis_error]
    Kobold.Telemetry.attach_handlers(:cache, events, status)

    {:ok, %{name: name, retry_after: retry_after}}
  end

  def store_hash(hash, original) do
    GenServer.cast(__MODULE__, {:set, hash, original})
  end

  def get_original(hash) do
    GenServer.call(__MODULE__, {:get, hash})
  end

  def delete_hash(hash) do
    GenServer.cast(__MODULE__, {:delete, hash})
  end

  # TODO: Force users to implement this function if they need to use telemetry
  defp emit(events, metadata), do: :telemetry.execute([:kobold, :cache | events], %{}, metadata)

  @impl true
  def handle_cast({:set, hash, original}, %{name: name, retry_after: retry_after} = state) do
    metadata = %{hash: hash, original: original}

    case Redix.command(name, ["SET", hash, original]) do
      {:ok, _} ->
        emit([:set, :success], metadata)
        {:noreply, state}

      {:error, %Redix.ConnectionError{}} ->
        emit([:set, :connection_error], metadata)
        Process.send_after(__MODULE__, {:set, hash, original}, retry_after)
        {:noreply, state}

      {:error, %Redix.Error{message: message}} ->
        emit([:set, :redis_error], metadata |> Map.put_new(:message, message))
        {:noreply, state}
    end
  end

  def handle_cast({:delete, hash}, %{name: name, retry_after: retry_after} = state) do
    metadata = %{hash: hash}

    case Redix.command(name, ["DEL", hash]) do
      {:ok, _} ->
        emit([:delete, :success], metadata)
        {:noreply, state}

      {:error, %Redix.ConnectionError{}} ->
        emit([:delete, :connection_error], metadata)
        Process.send_after(__MODULE__, {:delete, hash}, retry_after)
        {:noreply, state}

      {:error, %Redix.Error{message: message}} ->
        emit([:delete, :redis_error], metadata |> Map.put_new(:message, message))
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:get, hash}, _from, %{name: name, retry_after: retry_after} = state) do
    metadata = %{hash: hash}

    case Redix.command(name, ["GET", hash]) do
      {:ok, original} ->
        emit([:get, :success], metadata |> Map.put_new(:original, original))
        {:reply, original, state}

      {:error, %Redix.ConnectionError{}} ->
        emit([:get, :connection_error], metadata)
        Process.send_after(__MODULE__, {:get, hash}, retry_after)
        {:reply, nil, state}

      {:error, %Redix.Error{message: message}} ->
        emit([:get, :redis_error], metadata |> Map.put_new(:message, message))
        {:reply, nil, state}
    end
  end
end
