defmodule Kobold.Url do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "url" do
    field(:hash, :string, primary_key: true)
    field(:original, :string)
    field(:creation_date, :utc_datetime)
    field(:expiration_date, :utc_datetime)

    belongs_to(
      :user,
      Kobold.User,
      foreign_key: :user_id,
      references: :user_id,
      type: :binary_id
    )
  end

  @url_regex ~r"https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,255}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)"

  def insert(hash, original, creation_date, expiration_date \\ nil, user_id \\ nil) do
    params = %{
      hash: hash,
      original: original,
      creation_date: creation_date,
      expiration_date: expiration_date
    }

    url =
      %Kobold.Url{}
      |> cast(params, [:hash, :original, :creation_date, :expiration_date])
      |> validate_required([:hash, :original, :creation_date])
      |> validate_length(:original, max: 512)
      |> validate_format(:original, @url_regex, message: "invalid URL format")
      |> foreign_key_constraint(:user_id)

    if user_id do
      user =
        Kobold.User
        |> Kobold.Repo.get!(user_id)
        |> Kobold.Repo.preload(:urls)

      url =
        url
        |> change()
        |> put_assoc(:user, user)

      Kobold.Repo.insert!(url)
    else
      Kobold.Repo.insert!(url)
    end
  end
end
