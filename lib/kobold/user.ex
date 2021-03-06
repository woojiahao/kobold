defmodule Kobold.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  @primary_key {:user_id, :binary_id, autogenerate: true}
  schema "user" do
    field(:name, :string)
    field(:email, :string)
    field(:encrypted_password, :string)
    field(:password_salt, :string)
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

  @spec insert(struct()) :: {:ok, Kobold.User} | {:error, Ecto.Changeset}
  def insert(%{"email" => email, "name" => name, "password" => password}) do
    {salt, encrypted_password} = encrypt_password(password)
    fields = [:name, :email, :encrypted_password, :password_salt, :creation_date]

    user =
      %Kobold.User{}
      |> cast(
        %{
          name: name,
          email: email,
          encrypted_password: encrypted_password,
          password_salt: salt,
          creation_date: Kobold.Utility.utc_now()
        },
        fields
      )
      |> validate_required(fields)
      |> unique_constraint(:email, message: "email already exists")
      |> validate_length(:name, min: 2, message: "name must be more than 2 characters long")
      |> validate_length(:email, min: 2, message: "email must be more than 2 characters long")
      |> validate_format(:email, ~r/@/, message: "email format is invalid")

    Kobold.Repo.insert(user)
  end

  def login(%{"email" => email, "password" => password}) do
    if user = from(u in Kobold.User, where: u.email == ^email) |> Kobold.Repo.one() do
      if Bcrypt.verify_pass(password, user.encrypted_password) do
        {:ok, user}
      else
        {:error, "invalid password"}
      end
    else
      {:error, "invalid email"}
    end
  end

  def get(user_id) do
    Kobold.User
    |> Kobold.Repo.get!(user_id)
    |> Kobold.Repo.preload(:urls)
  end

  defp encrypt_password(password) do
    salt = Bcrypt.gen_salt()
    hash = Bcrypt.Base.hash_password(password, salt)
    {salt, hash}
  end
end
