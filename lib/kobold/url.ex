defmodule Kobold.Url do
  use Ecto.Schema
  import Ecto.Changeset

  schema "urls" do
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

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:expiration_date])
    |> validate_required([:hash, :original, :creation_date])
    |> validate_length(:original, max: 512)
    |> foreign_key_constraint(:user_id)
  end
end
