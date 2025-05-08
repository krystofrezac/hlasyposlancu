defmodule App.ParliamentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Parliament` context.
  """

  @doc """
  Generate a person.
  """
  def person_fixture(attrs \\ %{}) do
    {:ok, person} =
      attrs
      |> Enum.into(%{
        after_title: "some after_title",
        before_title: "some before_title",
        birth_date: ~U[2025-04-25 07:22:00Z],
        died_at: ~U[2025-04-25 07:22:00Z],
        first_name: "some first_name",
        last_name: "some last_name",
        sex: :male,
        updated_at: ~U[2025-04-25 07:22:00Z]
      })
      |> App.Parliament.create_person()

    person
  end

  @doc """
  Generate a deputy.
  """
  def deputy_fixture(attrs \\ %{}) do
    {:ok, deputy} =
      attrs
      |> Enum.into(%{
        person_id: 42
      })
      |> App.Parliament.create_deputy()

    deputy
  end

  @doc """
  Generate a body.
  """
  def body_fixture(attrs \\ %{}) do
    {:ok, body} =
      attrs
      |> Enum.into(%{
        abbreviation: "some abbreviation",
        from: ~D[2025-04-25],
        name: "some name",
        to: ~D[2025-04-25]
      })
      |> App.Parliament.create_body()

    body
  end

  @doc """
  Generate a voting.
  """
  def voting_fixture(attrs \\ %{}) do
    {:ok, voting} =
      attrs
      |> Enum.into(%{
        abstained: 42,
        body_id: 42,
        date_time: ~N[2025-05-07 16:05:00],
        did_not_vote: 42,
        logged_in: 42,
        point: 42,
        quorum: 42,
        result: :approved,
        voted_agains: 42,
        voted_for: 42,
        voting_type: :normal
      })
      |> App.Parliament.create_voting()

    voting
  end
end
