defmodule Kobold.Telemetry do
  # TODO: Add Telemetry.Metrics
  require Logger

  def handle_event([:kobold, :cache, :delete, :success], _, %{hash: hash}, _) do
    Logger.info("Deleted #{hash} successfully")
  end

  def handle_event(
        [:kobold, :cache, :delete, :redis_error],
        _,
        %{hash: hash, message: message},
        _
      ) do
    Logger.info("Failed to delete #{hash} due to #{message}")
  end

  def handle_event([:kobold, :cache, :set, :success], _, %{hash: hash, original: original}, _) do
    Logger.info("Save #{hash} for #{original} in cache")
  end

  def handle_event([:kobold, :cache, :get, :success], _, %{hash: hash, original: original}, _) do
    if is_nil(original),
      do: Logger.info("Cache does not contain cache for #{hash}"),
      else: Logger.info("Retrieved #{hash} for #{original} in cache")
  end
end
