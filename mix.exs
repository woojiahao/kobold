defmodule Kobold.MixProject do
  use Mix.Project

  def project do
    [
      app: :kobold,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Kobold.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:redix, ">= 0.0.0"},
      {:castore, ">= 0.0.0"},
      {:nimble_options, "~> 0.3.0"}
    ]
  end
end
