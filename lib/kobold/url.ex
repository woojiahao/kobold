defmodule Kobold.Url do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

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

    hash = if hash == :auto, do: generate_hash(original), else: hash

    # TODO: Maybe store decoded URL in db?
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

    attempt_insert(url)
  end

  def get(hash) do
    # TODO: Handle expiration date
    now = Kobold.Utility.utc_now()

    query =
      from(
        u in Kobold.Url,
        where:
          u.hash == ^hash and
            (is_nil(u.expiration_date) or
               u.expiration_date > ^now)
      )

    try do
      Kobold.Repo.one(query)
    rescue
      Ecto.MultipleResultsError ->
        raise Kobold.DuplicateHashException

      ex ->
        reraise(ex, __STACKTRACE__)
    end
  end

  def delete(hash, user_id) do
    
  end

  defp attempt_insert(url) do
    try do
      Kobold.Repo.insert(url)
    rescue
      Ecto.ConstraintError ->
        hash =
          if url.data.hash == :auto,
            do: generate_hash(url.data.original),
            else: raise(Kobold.DuplicateHashException)

        url = url |> cast(%{hash: hash}, [:hash])
        attempt_insert(url)
    end
  end

  defp generate_hash(url) do
    {:ok, hash} =
      URI.decode(url)
      |> Kobold.Utility.sha256()
      |> Base.encode64()
      |> Kobold.Utility.shuffle_random(6)

    hash
  end
end
