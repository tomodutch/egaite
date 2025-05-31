defmodule Egaite.Repo.Migrations.CreateDrawingPrompts do
  use Ecto.Migration

  def change do
    create table(:drawing_prompts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:drawing_prompts, [:text])
  end
end
