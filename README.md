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

## Hashing algorithm

The hashing algorithm is comprised of the following steps (taken from the design guide): 

1. Parse any URLs to remove any URL encoding
2. Compute a unique hash of the URL
3. Encode the hash of the URL using base64 or base62
4. Extract a 6-character long key from the hash (sufficient for use case)
5. Generate a random index to extract from the hash to form our key
6. Attempt to insert the key into the database
7. If the key cannot be inserted due to a primary key conflict, we will re-roll the random indices till it works

## Redirecting algorithm

When any path is called from the web server, the following algorithm is executed...

1. Query cache for path, if available, redirect to the original URL
2. If not available in cache, query database and redirect to the original URL
3. If database is queried, cache the data for future use
4. TODO: Add telemetry

## TODO

Check out the following projects:

- [Token authentication](https://github.com/ueberauth/guardian)
- [Multi-provide authentication frameworks](https://github.com/pow-auth/assent)
- [Authentication systems](https://github.com/ueberauth/ueberauth)

### Features

- [ ] Anonymous link generation
- [ ] User-based link generation
- [ ] Telemetry
- [ ] User management
- [ ] Front-end

### Guide

- Discuss the differences between hashing and encoding