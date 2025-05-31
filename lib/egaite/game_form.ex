defmodule Egaite.GameForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :nickname, :string
    field :game_name, :string
    field :rounds, :integer
    field :bot_count, :integer
    field :category_ids, {:array, :binary_id}, default: []
  end

  @doc false
  def changeset(game_form, attrs) do
    game_form
    |> cast(attrs, [:nickname, :game_name, :rounds, :bot_count, :category_ids])
    |> validate_required([:nickname, :game_name, :rounds, :bot_count])
    |> validate_number(:rounds, greater_than: 0, less_than_or_equal_to: 10)
    |> validate_number(:bot_count, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> validate_category_ids()
  end

  defp validate_category_ids(changeset) do
    case get_field(changeset, :category_ids) do
      [] -> add_error(changeset, :category_ids, "At least one category must be selected")
      _ -> changeset
    end
  end
end
