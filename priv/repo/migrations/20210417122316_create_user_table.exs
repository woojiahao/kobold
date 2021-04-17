defmodule Kobold.Repo.Migrations.CreateUserTable do
  use Ecto.Migration

  def change do
    create table(:user, primary_key: false) do
      add :user_id, :uuid, primary_key: true, null: false
      add :name, :string, size: 20, null: false
      add :email, :string, size: 32, null: false
      add :creation_date, :utc_datetime, null: false
      add :last_login, :utc_datetime
    end
  end
end
