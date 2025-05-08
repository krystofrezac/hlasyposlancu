defmodule App.Repo.Migrations.CreateVoting do
  use Ecto.Migration

  def change do
    create table(:voting, primary_key: [name: :id, type: :bigint]) do
      add :body_id, references(:body)
      add :point, :integer, null: false
      add :date_time, :naive_datetime, null: false
      add :voted_for, :integer, null: false
      add :voted_against, :integer, null: false
      add :abstained, :integer, null: false
      add :did_not_vote, :integer, null: false
      add :logged_in, :integer, null: false
      add :quorum, :integer, null: false
      add :voting_type, :string, null: false
      add :result, :string, null: false
      add :title, :string
    end
  end
end
