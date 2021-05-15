defmodule Kobold.Server do
  import Plug.Conn

  # TODO: Log any responses

  defmacro __using__(_opts) do
    quote do
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

      plug(:dispatch)
    end
  end

  def invalid_request(conn, reason) do
    error = %{
      "request_status" => "error",
      "http_code" => 400,
      "http_message" => "invalid request",
      "error_reason" => reason
    }

    conn
    |> set_content_type
    |> respond(400, error)
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

  def internal_server_error(conn, error) do
    error =
      build_error_response(
        500,
        "internal server error",
        "#{error}, contact the owner of the API"
      )

    conn
    |> set_content_type
    |> respond(500, error)
  end

  defp build_error_response(status, message, error) do
    %{
      "request_status" => "error",
      "http_code" => status,
      "http_message" => message,
      "error_reason" => error
    }
  end

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
