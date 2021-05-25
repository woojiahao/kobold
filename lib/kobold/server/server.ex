defmodule Kobold.Server do
  import Plug.Conn

  # TODO: Log any responses

  defmacro __using__(authorize \\ false) do
    quote bind_quoted: [authorize: authorize] do
      use Plug.Router
      require Logger
      import Kobold.Server
      alias Kobold.User, as: User
      alias Kobold.Url, as: Url

      if Mix.env() == :dev do
        use Plug.Debugger
      end

      plug(Plug.Logger)
      plug(:match)

      plug(Plug.Parsers,
        parsers: [:json],
        pass: ["application/json"],
        json_decoder: Jason
      )

      if authorize do
        plug(:authorize)
      end

      plug(:dispatch)
    end
  end

  def invalid_request(conn, reason) do
    error = build_error_response(400, "invalid request", reason)

    conn
    |> set_content_type
    |> respond(400, error)
  end

  def not_found(conn, reason) do
    error = build_error_response(404, "not found", reason)

    conn
    |> set_content_type
    |> respond(404, error)
  end

  def ok(conn, message) do
    response = %{
      "request_status" => "success",
      "http_code" => 200,
      "http_message" => "ok",
      "message" => message
    }

    conn
    |> set_content_type
    |> respond(200, response)
  end

  def created(conn, message) do
    response = %{
      "request_status" => "success",
      "http_code" => 201,
      "http_message" => "created",
      "message" => message
    }

    conn
    |> set_content_type
    |> respond(201, response)
  end

  def issue_jwt_token(conn, access_token, refresh_token) do
    response = %{
      "message" => "JWT token issued",
      "access_token" => access_token,
      "refresh_token" => refresh_token
    }

    conn
    |> set_content_type
    |> respond(201, response)
  end

  @spec internal_server_error(Plug.Conn.t(), list() | String.t()) :: Plug.Conn.t()
  def internal_server_error(conn, error) do
    error =
      build_error_response(
        500,
        "internal server error",
        error
      )

    conn
    |> set_content_type
    |> respond(500, error)
  end

  def authorize(conn, _opts) do
    authorization = conn |> get_authorization_header()
    IO.puts("authorizing")

    cond do
      is_nil(authorization) ->
        conn

      :ok = Kobold.Guardian.verify_token(authorization) ->
        conn

      :error = Kobold.Guardian.verify_token(authorization) ->
        conn |> invalid_request("invalid authorization token")
    end
  end

  def get_authorization_header(conn) do
    case authorization = conn |> Plug.Conn.get_req_header("authorization") |> List.last() do
      nil -> nil
      _ -> authorization |> String.replace_leading("Bearer ", "")
    end
  end

  defp build_error_response(status, message, error) when is_bitstring(error) do
    %{
      "request_status" => "error",
      "http_code" => status,
      "http_message" => message,
      "error_reason" => error
    }
  end

  defp build_error_response(status, message, errors) when is_list(errors) do
    %{
      "request_status" => "error",
      "http_code" => status,
      "http_message" => message,
      "errors" => errors
    }
  end

  defp build_error_response(status, message, error) when is_atom(error),
    do: build_error_response(status, message, Atom.to_string(error))

  defp respond(conn, status, body) do
    send_resp(conn, status, Jason.encode!(body))
  end

  defp set_content_type(conn) do
    conn
    |> update_resp_header(
      "content-type",
      "application/json; charset=utf-8",
      &(&1 <> "; charset=utf-8")
    )
  end
end
