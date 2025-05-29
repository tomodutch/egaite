defmodule Egaite.GameForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :nickname, :string
    field :game_name, :string
    field :rounds, :integer
  end

  @doc false
  def changeset(form, attrs) do
    form
    |> cast(attrs, [:nickname, :game_name, :rounds])
    |> validate_required([:nickname, :game_name, :rounds])
    |> validate_number(:rounds, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
  end
end
