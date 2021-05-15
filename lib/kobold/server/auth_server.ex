defmodule Kobold.Server.AuthServer do
  use Kobold.Server

  @password_regex ~r/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$/

  post "/signup" do
    signup = enforce_signup_data(conn.body_params)

    case signup do
      {:ok, signup} ->
        case validate_raw_password(signup["password"]) do
          {:ok, _password} ->
            case User.insert(signup) do
              {:ok, _user} -> created(conn, "user created successfully")
              {:error, _changeset} -> internal_server_error(conn, "failed to create user")
            end

          {:error, reason} ->
            invalid_request(conn, reason)
        end

      {:error, reason} ->
        invalid_request(conn, reason)
    end
  end

  defp enforce_signup_data(
         %{"email" => _email, "name" => _name, "password" => _password} = signup
       ),
       do: {:ok, signup}

  defp enforce_signup_data(_),
    do: {:error, "signup data missing required fields: [email, name, password]"}

  defp validate_raw_password(raw_password) do
    if(Regex.match?(@password_regex, raw_password)) do
      {:ok, raw_password}
    else
      {:error,
       "password requires at least 1 lowercase letter, 1 uppercase letter, 1 digit, 1 symbol"}
    end
  end
end
