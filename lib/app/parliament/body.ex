defmodule App.Parliament.Body do
  use Ecto.Schema
  import Ecto.Changeset

  schema "body" do
    field :name, :string
    field :to, :date
    field :from, :date
    field :abbreviation, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(body, attrs) do
    body
    |> cast(attrs, [:id, :abbreviation, :name, :from, :to])
    |> validate_required([:id, :abbreviation, :name, :from])
  end
end
