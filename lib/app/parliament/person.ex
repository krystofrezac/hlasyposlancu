defmodule App.Parliament.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "person" do
    field :before_title, :string
    field :first_name, :string
    field :last_name, :string
    field :after_title, :string
    field :birth_date, :date
    field :sex, Ecto.Enum, values: [:male, :female]
    field :updated_at, :date
    field :died_at, :date
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [
      :id,
      :before_title,
      :first_name,
      :last_name,
      :after_title,
      :birth_date,
      :sex,
      :updated_at,
      :died_at
    ])
    |> validate_required([:id, :first_name, :last_name, :birth_date, :sex])
  end
end
