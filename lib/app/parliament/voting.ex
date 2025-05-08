defmodule App.Parliament.Voting do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Parliament.Body

  schema("voting") do
    field :point, :integer
    field :date_time, :naive_datetime
    field :voted_for, :integer
    field :voted_against, :integer
    field :abstained, :integer
    field :did_not_vote, :integer
    field :logged_in, :integer
    field :quorum, :integer
    field :voting_type, Ecto.Enum, values: [:normal, :manual, :error]

    field :result, Ecto.Enum,
      values: [:approved, :rejected, :unknown, :not_public, :quorum_not_reached]

    field :title, :string

    belongs_to :body, Body
  end

  @doc false
  def changeset(voting, attrs) do
    voting
    |> cast(attrs, [
      :id,
      :body_id,
      :point,
      :date_time,
      :voted_for,
      :voted_against,
      :abstained,
      :did_not_vote,
      :logged_in,
      :quorum,
      :voting_type,
      :result,
      :title
    ])
    |> validate_required([
      :id,
      :body_id,
      :point,
      :date_time,
      :voted_for,
      :voted_against,
      :abstained,
      :did_not_vote,
      :logged_in,
      :quorum,
      :voting_type,
      :result
    ])
  end
end
