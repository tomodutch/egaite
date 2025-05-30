defmodule Egaite.NameGenerator do
  @moduledoc """
  Generates random names for players in the game.
  """

  @adjectives ["Swift", "Clever", "Brave", "Witty", "Mighty", "Sneaky"]
  @animals ["Fox", "Tiger", "Owl", "Bear", "Eagle", "Panther"]

  @doc """
  Generates a random name
  """
  def generate_name do
    "#{Enum.random(@adjectives)}#{Enum.random(@animals)}"
  end
end
