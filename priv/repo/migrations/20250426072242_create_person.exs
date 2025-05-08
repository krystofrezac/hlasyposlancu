defmodule App.Repo.Migrations.CreatePerson do
  use Ecto.Migration

  def change do
    create table(:person, primary_key: [name: :id, type: :bigint]) do
      add :before_title, :string
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :after_title, :string
      add :birth_date, :date, null: false
      add :sex, :string, null: false
      add :updated_at, :date
      add :died_at, :date
    end
  end
end
