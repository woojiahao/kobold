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

  def get_user_id(nil), do: nil

  def get_user_id(token) do
    with {:ok, claims} <- decode_and_verify(token) do
      claims["sub"]
    end
  end

  def issue_token(user_id) do
    with {:ok, access_token, _} <- encode_and_sign(user_id),
         {:ok, refresh_token, _} <- encode_and_sign(user_id, %{}, token_type: "refresh") do
      {:ok, access_token, refresh_token}
    else
      {:error, _} ->
        {:error, "Error attempting to issue token"}
    end
  end

  def refresh_token(refresh_token) do
    with {:ok, _, {new_access_token, _}} <- exchange(refresh_token, "refresh", "access"),
         {:ok, user_id, _} <- resource_from_token(new_access_token),
         {:ok, new_refresh_token, _} <- encode_and_sign(user_id, %{}, token_type: "refresh") do
      {:ok, new_access_token, new_refresh_token}
    else
      {:error, _} -> {:error, "Error attempting to refresh token"}
    end
  end

  def revoke_token(token) do
    {status, _} = revoke(token)
    status
  end

  def verify_token(token) do
    {status, _} = decode_and_verify(token, %{"typ" => "access"})
    status
  end
end
