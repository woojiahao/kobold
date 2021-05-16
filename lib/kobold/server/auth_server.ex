defmodule Kobold.Server.AuthServer do
  use Kobold.Server

  post "/signup" do
    case enforce_signup_data(conn.body_params) do
      {:ok, signup} ->
        case validate_raw_password(signup["password"]) do
          {:ok, _password} ->
            case User.insert(signup) do
              {:ok, _user} ->
                created(conn, "user created successfully")

              {:error, changeset} ->
                errors =
                  changeset.errors
                  |> Enum.map(fn {_, {reason, _}} -> reason end)

                Logger.error(IO.inspect(errors))
                internal_server_error(conn, errors)
            end

          {:error, reason} ->
            invalid_request(conn, reason)
        end

      {:error, reason} ->
        invalid_request(conn, reason)
    end
  end

  post "/login" do
    case enforce_login_data(conn.body_params) do
      {:ok, login} ->
        case User.login(login) do
          {:ok, user} ->
            {:ok, token, _claims} = Kobold.Guardian.encode_and_sign(user.user_id)
            created(conn, token)

          {:error, reason} ->
            invalid_request(conn, reason)
        end

      {:error, reason} ->
        invalid_request(conn, reason)
    end
  end

  defp enforce_login_data(%{"email" => _, "password" => _} = login), do: {:ok, login}

  defp enforce_login_data(_),
    do: {:error, "login data missing required fields: [email, password]"}

  defp enforce_signup_data(%{"email" => _, "name" => _, "password" => _} = signup),
    do: {:ok, signup}

  defp enforce_signup_data(_),
    do: {:error, "signup data missing required fields: [email, name, password]"}

  @password_regex ~r/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$/
  defp validate_raw_password(raw_password) do
    if(Regex.match?(@password_regex, raw_password)) do
      {:ok, raw_password}
    else
      {:error,
       "password requires at least 1 lowercase letter, 1 uppercase letter, 1 digit, 1 symbol"}
    end
  end
end
