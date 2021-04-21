defmodule Kobold.Repo.Migrations.CreateUserTable do
  use Ecto.Migration

  def change do
    create table(:user, primary_key: false) do
      add :user_id, :uuid, primary_key: true, null: false
      add :name, :string, null: false
      add :email, :string, null: false
      add :creation_date, :utc_datetime, null: false
      add :last_login, :utc_datetime
    end

    create constraint(
      :user,
      :email_format,
      check: "email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'"
    )
    create unique_index(:user, [:email])
  end
end
