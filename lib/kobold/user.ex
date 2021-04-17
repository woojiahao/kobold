defmodule Kobold.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:user_id, :binary_id, autogenerate: true}
  schema "user" do
    field(:name, :string)
    field(:email, :string)
    field(:creation_date, :utc_datetime)
    field(:last_login, :utc_datetime)

    has_many(
      :urls,
      Kobold.Url,
      foreign_key: :user_id,
      references: :user_id,
      on_delete: :delete_all
    )
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:name, :email, :last_login])
    |> validate_required([:user_id, :name, :email, :creation_date])
    |> unique_constraint(:email)
    |> validate_length(:name, min: 2)
    |> validate_length(:email, min: 2)
    |> validate_format(:email, ~r/@/)
  end
end
