defmodule Kobold.Application do
  @moduledoc false

  @cache_name :redis_cache

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Kobold.Repo,
      build_caching_supervisor(@cache_name, 5_000),
      {Plug.Cowboy, scheme: :http, plug: Kobold.Server, options: [port: 4001]}
    ]

    opts = [strategy: :one_for_one, name: Kobold.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp build_caching_supervisor(cache_name, retry_after) do
    children = [
      {Redix, name: cache_name, port: 4002, sync_connect: true},
      {Kobold.Cache, cache_name: cache_name, retry_after: retry_after}
    ]

    %{
      id: Kobold.CacheSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :rest_for_one]]}
    }
  end
end
