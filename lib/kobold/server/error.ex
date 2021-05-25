defmodule Kobold.Server.Error do
  defmodule NotFoundError do
    defexception message: "Resource not found", plug_status: 404
  end

  defmodule BadRequestError do
    defexception message: "Bad request", plug_status: 400
  end

  defmodule InternalServerError do
    defexception message: "Internal server error encountered", errors: [], plug_status: 500
  end
end
