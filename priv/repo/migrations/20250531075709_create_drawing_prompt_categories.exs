defmodule Egaite.Repo.Migrations.CreateDrawingPromptCategories do
  use Ecto.Migration

  def change do
    create table(:drawing_prompt_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:drawing_prompt_categories, [:name])
  end
end
