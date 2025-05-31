defmodule Egaite.DrawingPromptCategory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "drawing_prompt_categories" do
    field :name, :string
    field :description, :string
    many_to_many :prompts, Egaite.DrawingPrompt,
      join_through: "drawing_prompts_drawing_prompt_categories"
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(drawing_prompt_categories, attrs) do
    drawing_prompt_categories
    |> cast(attrs, [:name, :description])
    |> unique_constraint(:name)
    |> validate_required([:name, :description])
    |> unique_constraint(:text)
  end
end
