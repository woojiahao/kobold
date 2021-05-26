defmodule Kobold.Telemetry do
  # TODO: Add Telemetry.Metrics
  require Logger

  def attach_handlers(module, events, status) do
    full_events =
      Kobold.Utility.permutations(events, status)
      |> Enum.map(&[:kobold, module | &1])

    name = "kobold-#{Atom.to_string(module)}-telemetry-handler"

    :ok =
      :telemetry.attach_many(
        name,
        full_events,
        &Kobold.Telemetry.handle_event/4,
        nil
      )

    Logger.info("Attached handlers for #{name}")
  end

  def handle_event([:kobold, :cache, :delete, :success], _, %{hash: hash}, _) do
    Logger.info("Deleted #{hash} successfully")
  end

  def handle_event([:kobold, :cache, :set, :success], _, %{hash: hash, original: original}, _) do
    Logger.info("Save #{hash} for #{original} in cache")
  end

  def handle_event([:kobold, :cache, :get, :success], _, %{hash: hash, original: original}, _) do
    if is_nil(original),
      do: Logger.info("Cache does not contain cache for #{hash}"),
      else: Logger.info("Retrieved #{hash} for #{original} in cache")
  end

  def handle_event([:kobold, :cache, _, :redis_error], _, %{message: message}, _) do
    Logger.info("Redis failed due to #{message}")
  end

  def handle_event([:kobold, :cache, _, :connection_error], _, _, _) do
    Logger.info("Redis failed to connect. Retrying...")
  end
end
