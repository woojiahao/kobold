# Kobold

URL shortening service built using Elixir for the backend, PostgreSQL for the database, and Redis for caching.

## Learning objectives

The key learning objective with this project is to work with Ecto and Phoenix in Elixir and to build a scalable system.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `kobold` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kobold, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/kobold](https://hexdocs.pm/kobold).

## Architecture

While pointed out by this [design guide](https://www.educative.io/courses/grokking-the-system-design-interview/m2ygV4E81AR) that a NoSQL would serve to provide better scaling options. However, the adapter for NoSQL databases like MongoDB, Cassandra, and Riak are severely outdated so I have chosen to go with a better maintained adapter that I was more familiar with -- PostgreSQL.

## TODO

Check out the following projects:

- [Token authentication](https://github.com/ueberauth/guardian)
- [Multi-provide authentication frameworks](https://github.com/pow-auth/assent)
- [Authentication systems](https://github.com/ueberauth/ueberauth)