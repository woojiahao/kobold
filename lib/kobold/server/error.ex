defmodule Kobold.Server.Error do
  defmodule BadRequestError do
    defexception message: "Bad request", plug_status: 400
  end

  defmodule UnauthorizedError do
    defexception message: "Unauthorized access", plug_status: 401
  end

  defmodule NotFoundError do
    defexception message: "Resource not found", plug_status: 404
  end

  defmodule InternalServerError do
    defexception message: "Something went wrong", errors: [], plug_status: 500
  end
end
