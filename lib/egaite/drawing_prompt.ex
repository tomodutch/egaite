defmodule Egaite.DrawingPrompt do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "drawing_prompts" do
    field :text, :string

    many_to_many :categories, Egaite.DrawingPromptCategory,
      join_through: "drawing_prompts_drawing_prompt_categories"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(drawing_prompt, attrs) do
    drawing_prompt
    |> cast(attrs, [:text])
    |> cast_assoc(:categories, with: &Egaite.DrawingPromptCategory.changeset/2)
    |> validate_required([:text])
    |> unique_constraint(:text)
  end
end
