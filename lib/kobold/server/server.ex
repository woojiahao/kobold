defmodule Kobold.Server do
  # TODO: Log any responses

  import Plug.Conn, only: [send_resp: 3, update_resp_header: 4]
  import Plug.Conn.Status, only: [reason_phrase: 1]

  defmacro __using__(authorize) do
    quote bind_quoted: [authorize: authorize] do
      require Logger

      import Kobold.Server, except: [handle_errors: 2]
      alias Kobold.Server.Error.InternalServerError
      alias Kobold.Server.Error.BadRequestError
      alias Kobold.Server.Error.NotFoundError

      alias Kobold.User, as: User
      alias Kobold.Url, as: Url

      use Plug.Router
      use Plug.ErrorHandler

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

      def handle_errors(conn, %{reason: err}) do
        %{plug_status: status, message: message, errors: errors} = err |> Map.merge(%{errors: []})
        body = if length(errors) == 0, do: message, else: errors
        error = build_error_response(status, reason_phrase(status), body)
        conn |> respond(status, error)
      end
    end
  end

  def build_error_response(status, message),
    do: %{
      "request_status" => "Error",
      "http_code" => status,
      "http_message" => message
    }

  def build_error_response(status, message, error) when is_bitstring(error),
    do: build_error_response(status, message) |> Map.merge(%{"error" => error})

  def build_error_response(status, message, errors) when is_list(errors),
    do: build_error_response(status, message) |> Map.merge(%{"errors" => errors})

  def build_error_response(status, message, error) when is_atom(error),
    do: build_error_response(status, message, Atom.to_string(error))

  def respond(conn, status, body) do
    conn |> set_content_type |> send_resp(status, Jason.encode!(body))
  end

  def set_content_type(conn) do
    conn
    |> update_resp_header(
      "content-type",
      "application/json; charset=utf-8",
      &(&1 <> "; charset=utf-8")
    )
  end

  def ok(conn, message) do
    response = %{
      "request_status" => "success",
      "http_code" => 200,
      "http_message" => "ok",
      "message" => message
    }

    conn
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
    |> respond(201, response)
  end

  def issue_jwt_token(conn, access_token, refresh_token) do
    response = %{
      "message" => "JWT token issued",
      "access_token" => access_token,
      "refresh_token" => refresh_token
    }

    conn
    |> respond(201, response)
  end

  def authorize(conn, _opts) do
    authorization = conn |> get_authorization_header()

    if is_nil(authorization) do
      conn
    else
      case Kobold.Guardian.verify_token(authorization) do
        :ok ->
          conn

        :error ->
          raise Kobold.Server.Error.InvalidRequestError,
            message: "Invalid JWT provided in Authorization header"
      end
    end
  end

  def get_authorization_header(conn) do
    case authorization = conn |> Plug.Conn.get_req_header("authorization") |> List.last() do
      nil -> nil
      _ -> authorization |> String.replace_leading("Bearer ", "")
    end
  end
end
