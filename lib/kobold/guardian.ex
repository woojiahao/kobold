defmodule Kobold.Guardian do
  use Guardian, otp_app: :kobold

  def subject_for_token(uuid, _claims) do
    sub = to_string(uuid)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Kobold.User.get(id)
    {:ok, resource}
  end
end
