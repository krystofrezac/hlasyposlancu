defmodule App.Parliament.Deputy do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Parliament.Person

  schema "deputy" do
    belongs_to :person, Person
  end

  @doc false
  def changeset(deputy, attrs) do
    deputy
    |> cast(attrs, [:id, :person_id])
    |> validate_required([:id, :person_id])
  end
end
