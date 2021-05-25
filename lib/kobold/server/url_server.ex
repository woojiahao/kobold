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
    # TODO: Parse expiration_date
    token = conn |> get_authorization_token()

    IO.inspect(conn.body_params)
    IO.inspect(token)
    IO.inspect(Kobold.Guardian.get_user_id(token))

    %{"original" => original, "hash" => hash, "expiration_date" => expiration_date} =
      %{"original" => nil, "hash" => :auto, "expiration_date" => nil}
      |> Map.merge(conn.body_params)

    if is_nil(original), do: raise(BadRequestError, message: "Missing [original]")

    try do
      with {:ok, url} =
             Url.insert(original, hash, expiration_date, Kobold.Guardian.get_user_id(token)) do
        conn |> created(url.hash)
      end
    rescue
      Kobold.Exception.DuplicateHashException ->
        raise InternalServerError, message: "Cannot have duplicate hash"

      ex ->
        Logger.error("Failed to create hash")
        Logger.error(ex)
        raise InternalServerError
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
