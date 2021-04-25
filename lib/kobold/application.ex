defmodule Kobold.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Kobold.Repo,
      {Plug.Cowboy, scheme: :http, plug: Kobold.Server, options: [port: 4001]}
    ]

    opts = [strategy: :one_for_one, name: Kobold.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
