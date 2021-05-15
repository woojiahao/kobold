defmodule Kobold.Server.UrlServer do
  use Plug.Router
  require Logger

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/:path" do
    if path == "favicon.ico" do
      conn |> resp(200, "") |> put_resp_header("Content-Type", "image/x-icon")
    else
      original = Kobold.Cache.get_original(path)

      if !is_nil(original) do
        conn |> redirect(original)
      else
        url = Kobold.Url.get(path)

        if url == nil do
          # TODO: Display custom 404 path
          send_resp(conn, 404, "Invalid path")
        else
          Kobold.Cache.store_hash(url.hash, url.original)
          redirect(conn, url.original)
        end
      end
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

  defp redirect(conn, original) do
    Logger.info("redirecting to #{original}")
    conn |> resp(:found, "") |> put_resp_header("location", original)
  end
end
