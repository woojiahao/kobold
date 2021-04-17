defmodule Kobold.Repo do
  use Ecto.Repo,
    otp_app: :kobold,
    adapter: Ecto.Adapters.Postgres
end
