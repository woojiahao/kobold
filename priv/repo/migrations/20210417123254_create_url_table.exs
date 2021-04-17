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

    create index(:url, [:user_id])
  end
end
