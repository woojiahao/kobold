defmodule Kobold.Server do
  use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/:path" do
    # TODO: Add caching check

    if path == "favicon.ico" do
      conn |> resp(200, "") |> put_resp_header("Content-Type", "image/x-icon")
    else
      url = Kobold.Url.get(path)
      conn |> resp(:found, "") |> put_resp_header("location", url.original)
    end
  end

  post "/create" do
    # TODO: Create a hashed URL
    send_resp(conn, 200, "Creating URL")
  end

  delete "/delete/:hash" do
    # TODO: Restrict this to user only keys
    send_resp(conn, 200, "Deleting key")
  end

  match _ do
    send_resp(conn, 404, "Invalid path")
  end
end
