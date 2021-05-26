defmodule Kobold.Url do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2, where: 3]
  import Kobold.Utility, only: [utc_now: 0, parse_changeset_errors: 1]

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
  def insert(original, hash \\ :auto, expiration_date \\ nil, user_id \\ nil) do
    # TODO: Enforce specific rules for custom hashes
    hash = if hash == :auto, do: generate_hash(original), else: hash

    # TODO: Maybe store decoded URL in db?
    url =
      %Kobold.Url{}
      |> cast(
        %{
          hash: hash,
          original: original,
          creation_date: utc_now(),
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

  def get(hash, user_id \\ :ignore) do
    # TODO: Handle expiration date
    # TODO: Handle corner case where hash might have expired, delete this and inform delete that it was recently deleted
    now = Kobold.Utility.utc_now()

    query =
      from(
        u in Kobold.Url,
        where:
          u.hash == ^hash and
            (is_nil(u.expiration_date) or
               u.expiration_date > ^now)
      )

    query = if user_id != :ignore, do: query |> where_user_id(user_id), else: query

    try do
      Kobold.Repo.one(query)
    rescue
      Ecto.MultipleResultsError ->
        raise Kobold.Exception.DuplicateHashException

      ex ->
        reraise(ex, __STACKTRACE__)
    end
  end

  def delete(hash, user_id) do
    url = get(hash, user_id)

    case Kobold.Repo.delete(url) do
      {:ok, _} -> {:ok, "Delete successful"}
      {:error, changeset} -> {:error, parse_changeset_errors(changeset)}
    end
  end

  defp where_user_id(query, user_id), do: query |> where([u], u.user_id == ^user_id)

  defp attempt_insert(url) do
    try do
      Kobold.Repo.insert(url)
    rescue
      Ecto.ConstraintError ->
        hash =
          if url.data.hash == :auto,
            do: generate_hash(url.data.original),
            else: raise(Kobold.Exception.DuplicateHashException)

        url = url |> cast(%{hash: hash}, [:hash])
        attempt_insert(url)
    end
  end

  defp generate_hash(url) do
    # TODO: Just use random generator lol
    {:ok, hash} =
      URI.decode(url)
      |> Kobold.Utility.sha256()
      |> Base.encode64()
      |> Kobold.Utility.shuffle_random(6)

    hash
  end
end
