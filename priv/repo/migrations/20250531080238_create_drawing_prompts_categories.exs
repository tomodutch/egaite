defmodule Egaite.Repo.Migrations.CreateDrawingPromptsCategoriesIntersectionTable do
  use Ecto.Migration

  def change do
  create table(:drawing_prompts_drawing_prompt_categories, primary_key: false) do
    add :drawing_prompt_id, references(:drawing_prompts, type: :binary_id, on_delete: :delete_all), null: false
    add :drawing_prompt_category_id, references(:drawing_prompt_categories, type: :binary_id, on_delete: :delete_all), null: false
  end

  create unique_index(:drawing_prompts_drawing_prompt_categories, [:drawing_prompt_id, :drawing_prompt_category_id])
  end
end
