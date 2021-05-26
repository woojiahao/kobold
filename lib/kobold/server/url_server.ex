defmodule Kobold.Server.UrlServer do
  # TODO: Handle when there is not enough storage
  use Kobold.Server, authorize: true

  get "/:path" do
    # TODO: Add telemetry to this
    case path do
      "favicon.ico" ->
        conn |> resp(200, "") |> put_resp_header("Content-Type", "image/x-icon")

      _ ->
        original = Cache.get_original(path)

        if !is_nil(original) do
          conn |> redirect(original)
        else
          case url = Url.get(path) do
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

    expiration_date =
      case validate_expiration_date(expiration_date) do
        {:ok, expiration_datetime} -> expiration_datetime
        {:error, reason} -> raise BadRequestError, message: reason
        {:internal_server_error, reason} -> raise InternalServerError, message: reason
        _ -> nil
      end

    try do
      {:ok, url} = Url.insert(original, hash, expiration_date, user_id)
      # TODO: Allow customisable created messages?
      conn |> created(url.hash)
    rescue
      Kobold.Exception.DuplicateHashException ->
        raise BadRequestError, message: "Cannot have duplicate hash"

      ex ->
        Logger.error("Failed to create hash")
        Logger.error(ex)
        raise InternalServerError
    end
  end

  delete "/delete/:hash" do
    # TODO: Check for any active conn and delay delete till all closed?
    user_id =
      conn
      |> get_authorization_token()
      |> Kobold.Guardian.get_user_id()

    if is_nil(user_id), do: raise(UnauthorizedError)

    case Url.delete(hash, user_id) do
      {:ok, _} ->
        Cache.delete_hash(hash)
        conn |> ok("Deleted hash")

      {:error, errors} ->
        raise InternalServerError, errors: errors
    end
  end

  match _ do
    send_resp(conn, 404, "Invalid path")
  end

  @spec validate_hash(String.t() | atom()) :: {:ok, String.t() | atom()} | {:error, String.t()}
  defp validate_hash(:auto), do: {:ok, :auto}

  @blacklist_words ~w(create delete signup login logout auth refresh kobold)
  defp validate_hash(hash) when hash in @blacklist_words,
    do: {:error, "Hash is a reserved word and cannot be used. Try again."}

  @blacklist_chars ~w(& / \\ ? % \( \) [ ] < > =)
  defp validate_hash(hash) do
    if hash |> String.graphemes() |> Enum.any?(&(&1 in @blacklist_chars)),
      do: {:error, "Hash cannot contain invalid symbols: [&=/\\%()[]<>]"},
      else: {:ok, hash}
  end

  @spec validate_expiration_date(integer() | String.t()) ::
          nil | {:ok, DateTime.t()} | {:error, String.t()} | {:internal_server_error, String.t()}
  defp validate_expiration_date(nil), do: nil

  defp validate_expiration_date(expiration_date_epoch) when is_bitstring(expiration_date_epoch),
    do: validate_expiration_date(String.to_integer(expiration_date_epoch))

  defp validate_expiration_date(expiration_date_epoch) do
    with {:ok, expiration_datetime} <- DateTime.from_unix(expiration_date_epoch),
         now_datetime <- Kobold.Utility.utc_now(),
         {:ok, expiration_date} <- datetime_to_date(expiration_datetime),
         {:ok, now_date} <- datetime_to_date(now_datetime),
         compared <- Date.compare(expiration_date, now_date),
         false <- compared in [:lt, :eq] do
      {:ok, expiration_datetime}
    else
      {:error, :invalid_unix_time} ->
        {:error, "Invalid expiration date provided."}

      {:error, :invalid_date} ->
        {:internal_server_error, "Failed to create Date from datetime"}

      true ->
        {:error,
         "Invalid expiration date provided. Cannot be before or on the same date as today."}
    end
  end

  @spec datetime_to_date(DateTime.t()) :: {:ok, Date.t()} | {:error, atom()}
  defp datetime_to_date(datetime) do
    day = datetime.day
    month = datetime.month
    year = datetime.year
    Date.new(year, month, day)
  end

  defp redirect(conn, original) do
    Logger.info("redirecting to #{original}")
    conn |> resp(:found, "") |> put_resp_header("location", original)
  end
end
