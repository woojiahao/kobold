import Config

# TODO: Dynamically load these configurations
config :kobold, Kobold.Repo,
  database: "kobold",
  username: "postgres",
  password: "root",
  hostname: "localhost"

config :kobold, ecto_repos: [Kobold.Repo]
