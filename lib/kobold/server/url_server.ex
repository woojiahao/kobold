defmodule Kobold.Server.UrlServer do
  # TODO: Handle when there is not enough storage
  use Kobold.Server, authorize: true

  get "/:path" do
    # TODO: Add telemetry to this
    case path do
      "favicon.ico" ->
        conn |> resp(200, "") |> put_resp_header("Content-Type", "image/x-icon")

      _ ->
        original = Kobold.Cache.get_original(path)

        if !is_nil(original) do
          conn |> redirect(original)
        else
          case url = Kobold.Url.get(path) do
            nil ->
              raise NotFoundError, message: "Invalid path"

            _ ->
              Kobold.Cache.store_hash(url.hash, url.original)
              conn |> redirect(url.original)
          end
        end
    end
  end

  post "/create" do
    # TODO: Create a hashed URL
    # TODO: Deny based on type of path such as /auth or /delete or /create
    create = conn.body_params

    authorization = conn |> get_authorization_header()

    IO.inspect(authorization)

    original = Map.fetch(create, "original")
    hash = Map.get(create, "hash", :auto)
    expiration_date = Map.get(create, "expiration_date")

    case original do
      :error ->
        raise BadRequestError, message: "missing [original]"

      _ ->
        nil
        # TODO: Handle custom hashes
        # Kobold.Url.insert(%{original: original, hash: hash, expiration_date: expiration_date, user_id: })
    end
  end

  delete "/delete/:hash" do
    # TODO: Restrict this to user only keys
    send_resp(conn, 200, "Deleting key")
  end

  match _ do
    send_resp(conn, 404, "Invalid path")
  end

  defp redirect(conn, original) do
    Logger.info("redirecting to #{original}")
    conn |> resp(:found, "") |> put_resp_header("location", original)
  end
end
