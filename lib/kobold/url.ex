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

  @doc """
  Creates a shortened URL.
  """
  @spec insert(keyword()) :: {:ok, Kobold.Url} | {:error, Ecto.Changeset}
  def insert(params) do
    creation_date = DateTime.truncate(DateTime.utc_now(), :second)
    # TODO: Enforce specific rules for custom hashes
    hash = Keyword.get(params, :hash, :auto)
    original = Keyword.fetch!(params, :original)
    expiration_date = Keyword.get(params, :expiration_date)
    user_id = Keyword.get(params, :user_id)

    {:ok, hash} =
      if hash == :auto do
        # Automatically generate the hash if no custom hash is provided
        URI.decode(original)
        |> Kobold.Utility.sha256()
        |> Base.encode64()
        |> Kobold.Utility.shuffle_random(6)
      else
        hash
      end

    url =
      %Kobold.Url{}
      |> cast(
        %{
          hash: hash,
          original: original,
          creation_date: creation_date,
          expiration_date: expiration_date
        },
        [:hash, :original, :creation_date, :expiration_date]
      )
      |> validate_required([:hash, :original, :creation_date])
      |> validate_length(:original, max: 512)
      |> validate_format(:original, @url_regex, message: "invalid URL format")
      |> foreign_key_constraint(:user_id)

    url =
      if user_id do
        user = Kobold.User.get(user_id)
        url |> change() |> put_assoc(:user, user)
      else
        url
      end

    Kobold.Repo.insert!(url)
  end
end
