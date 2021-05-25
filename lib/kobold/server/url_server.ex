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
    # TODO: Parse expiration_date
    # TODO: Limit custom user hashes

    %{"original" => original, "hash" => hash, "expiration_date" => expiration_date} =
      %{"original" => nil, "hash" => :auto, "expiration_date" => nil}
      |> Map.merge(conn.body_params)

    if is_nil(original), do: raise(BadRequestError, message: "Missing [original]")

    user_id =
      conn
      |> get_authorization_token()
      |> Kobold.Guardian.get_user_id()

    hash =
      case validate_hash(if is_nil(user_id), do: :auto, else: hash) do
        {:ok, hash} -> hash
        {:error, reason} -> raise BadRequestError, message: reason
      end

    try do
      {:ok, url} = Url.insert(original, hash, expiration_date, user_id)
      # TODO: Allow customisable created messages?
      conn |> created(url.hash)
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

  defp validate_hash(:auto), do: {:ok, :auto}

  @blacklist_words ~w(create delete signup login logout auth refresh kobold)
  defp validate_hash(hash) when hash in @blacklist_words,
    do: {:error, "Hash is a reserved word and cannot be used. Try again."}

  @blacklist_chars Regex.compile!("([&/\\?%()\[\]<>=])*")
  defp validate_hash(hash) do
    if Regex.match?(@blacklist_chars, hash),
      do: {:error, "Hash cannot contain invalid symbols: [&=/\\%()[]<>]"},
      else: {:ok, hash}
  end

  defp redirect(conn, original) do
    Logger.info("redirecting to #{original}")
    conn |> resp(:found, "") |> put_resp_header("location", original)
  end
end
