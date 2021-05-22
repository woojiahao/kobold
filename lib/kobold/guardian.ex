defmodule Kobold.Guardian do
  use Guardian, otp_app: :kobold

  def subject_for_token(uuid, _claims) do
    sub = to_string(uuid)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Kobold.User.get(id).user_id
    {:ok, resource}
  end

  def issue_token(user_id) do
    case encode_and_sign(user_id) do
      {:ok, access_token, _} ->
        case encode_and_sign(user_id, %{}, token_type: "refresh") do
          {:ok, refresh_token, _} -> {:ok, access_token, refresh_token}
          {:error, _} -> {:error, "Error attempting to issue refresh token."}
        end

      {:error, _} ->
        {:error, "Error attempting to issue access token."}
    end
  end

  def refresh_token(refresh_token) do
    case exchange(refresh_token, "refresh", "access") do
      {:ok, _, {new_access_token, _}} ->
        case resource_from_token(new_access_token) do
          {:ok, user_id, _} ->
            case encode_and_sign(user_id, %{}, token_type: "refresh") do
              {:ok, new_refresh_token, _} ->
                {:ok, new_access_token, new_refresh_token}

              {:error, _} ->
                {:error, "Error attempting to issue new refresh token."}
            end

          {:error, _} ->
            {:error, "Error attempting to extract resource from access token."}
        end

      {:error, _} ->
        {:error,
         "Error attempting to exchange refresh token for access token. Ensure that refresh token is valid."}
    end
  end
end
