defmodule Kobold.Repo.Migrations.CreateUrlTable do
  use Ecto.Migration

  def change do
    create table(:url, primary_key: false) do
      add :hash, :string, primary_key: true, null: false
      add :original, :string, size: 512, null: false
      add :creation_date, :utc_datetime, null: false
      add :expiration_date, :utc_datetime
      add :user_id, references(:user, type: :uuid, column: :user_id)
    end

    create constraint(
      :url,
      :url_format,
      check: "original :: text ~ '^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$' :: text"
    )
    create index(:url, [:user_id])
  end
end
