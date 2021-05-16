import Config
import System, only: [get_env: 1]

import_config "#{Mix.env()}.secret.exs"

config :kobold, Kobold.Repo,
  database: get_env("KOBOLD_DB"),
  username: get_env("KOBOLD_DB_USER"),
  password: get_env("KOBOLD_DB_PASS"),
  hostname: get_env("KOBOLD_DB_URL")

config :kobold, ecto_repos: [Kobold.Repo]

config :kobold, Kobold.Guardian,
  issuer: Kobold,
  secret_key: get_env("KOBOLD_JWT_SECRET")
