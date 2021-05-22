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
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
