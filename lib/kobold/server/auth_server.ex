defmodule Kobold.Server.AuthServer do
  @moduledoc """
  This server is only responsible for issuing and refreshing JWT tokens for access to the resource server on port 4001.
  It will not be responsible for verifying if the token is valid. That is the responsibility of the resource server to
  verify every JWT included in the request body.

  This authentication server uses JWTs as the access tokens while issuing refresh tokens to ensure that the client has
  valid access tokens all the time. A refresh token is used over refreshing the JWT internally as it makes the adoption
  of other OAuth flows a lot easier for the client.
  """
  use Kobold.Server
  import Kobold.Guardian

  post "/auth/signup" do
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
                raise InternalServerError, errors: errors
            end

          {:error, reason} ->
            raise BadRequestError, message: reason
        end

      {:error, reason} ->
        raise BadRequestError, message: reason
    end
  end

  post "/auth/login" do
    # TODO: Update database
    case enforce_login_data(conn.body_params) do
      {:ok, login} ->
        with {:ok, user} <- User.login(login),
             {:ok, access_token, refresh_token} <- issue_token(user.user_id) do
          issue_jwt_token(conn, access_token, refresh_token)
        else
          {:error, reason} -> raise InternalServerError, message: reason
        end

      {:error, reason} ->
        raise BadRequestError, message: reason
    end
  end

  post "/auth/refresh" do
    case enforce_refresh_data(conn.body_params) do
      {:ok, refresh_token} ->
        case refresh_token(refresh_token) do
          {:ok, access_token, refresh_token} -> issue_jwt_token(conn, access_token, refresh_token)
          {:error, reason} -> raise InternalServerError, message: reason
        end

      {:error, reason} ->
        raise BadRequestError, message: reason
    end
  end

  post "/auth/logout" do
    # TODO: Update database
    case enforce_logout_data(conn.body_params) do
      {:ok, %{"access_token" => access_token, "refresh_token" => refresh_token}} ->
        with :ok <- revoke_token(access_token),
             :ok <- revoke_token(refresh_token) do
          ok(conn, "successfully revoked access & refresh tokens")
        else
          :error -> raise InternalServerError, message: "unable to revoke refresh token"
        end

      {:error, reason} ->
        raise BadRequestError, message: reason
    end
  end

  defp enforce_logout_data(%{"access_token" => _, "refresh_token" => _} = logout),
    do: {:ok, logout}

  defp enforce_logout_data(_), do: {:error, "missing [access_token, refresh_token]"}

  defp enforce_refresh_data(%{"refresh_token" => refresh_token}), do: {:ok, refresh_token}

  defp enforce_refresh_data(_), do: {:error, "missing [refresh_token]"}

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
