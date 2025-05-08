defmodule App.Repo.Migrations.CreateBody do
  use Ecto.Migration

  def change do
    create table(:body, primary_key: [name: :id, type: :bigint]) do
      add :abbreviation, :string, null: false
      add :name, :text, null: false
      add :from, :date, null: false
      add :to, :date
    end
  end
end
