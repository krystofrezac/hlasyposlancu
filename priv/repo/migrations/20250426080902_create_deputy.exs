defmodule App.Repo.Migrations.CreateDeputy do
  use Ecto.Migration

  def change do
    create table(:deputy, primary_key: [name: :id, type: :bigint]) do
      add :person_id, references(:person)
    end
  end
end
