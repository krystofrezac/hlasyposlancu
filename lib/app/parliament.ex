defmodule App.Parliament do
  import Ecto.Query

  alias App.Parliament.Person
  alias App.Parliament.Deputy
  alias App.Parliament.Body
  alias App.Parliament.Voting
  alias App.Repo

  @doc """
  Upserts a person.

  ## Examples

      iex> upsert_person(%{field: value})
      {:ok, %Person{}}

      iex> upsert_person(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_person(attrs \\ %{}) do
    %Person{}
    |> Person.changeset(attrs)
    |> Repo.insert(conflict_target: :id, on_conflict: :replace_all)
  end

  @doc """
  Counts number of entries for person.

  ## Examples

      iex> count_person()
      3

  """
  def count_person() do
    query =
      from p in Person,
        select: count()

    Repo.one!(query)
  end

  @doc """
  Upserts a deputy.

  ## Examples

      iex> upsert_deputy(%{field: value})
      {:ok, %Deputy{}}

      iex> upsert_deputy(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_deputy(attrs \\ %{}) do
    %Deputy{}
    |> Deputy.changeset(attrs)
    |> Repo.insert(conflict_target: :id, on_conflict: :replace_all)
  end

  @doc """
  Counts number of entries for deputy.

  ## Examples

      iex> count_deputy()
      3

  """
  def count_deputy() do
    query =
      from p in Deputy,
        select: count()

    Repo.one!(query)
  end

  @doc """
  upserts a body.

  ## Examples

      iex> upsert_body(%{field: value})
      {:ok, %Body{}}

      iex> upsert_body(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_body(attrs \\ %{}) do
    %Body{}
    |> Body.changeset(attrs)
    |> Repo.insert(conflict_target: :id, on_conflict: :replace_all)
  end

  @doc """
  Counts number of entries for body.

  ## Examples

      iex> count_body()
      3

  """
  def count_body() do
    query =
      from p in Body,
        select: count()

    Repo.one!(query)
  end

  @doc """
  Upserts a voting.

  ## Examples

      iex> upsert_voting(%{field: value})
      {:ok, %Voting{}}

      iex> upsert_voting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_voting(attrs \\ %{}) do
    %Voting{}
    |> Voting.changeset(attrs)
    |> Repo.insert(conflict_target: :id, on_conflict: :replace_all)
  end

  @doc """
  Counts number of entries for voting.

  ## Examples

      iex> count_voting()
      3

  """
  def count_voting() do
    query =
      from p in Voting,
        select: count()

    Repo.one!(query)
  end
end
