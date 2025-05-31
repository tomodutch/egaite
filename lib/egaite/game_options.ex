defmodule Egaite.GameOptions do
  @moduledoc """
  Game options for Egaite.
  """
  alias Egaite.DrawingPrompt

  defstruct game_name: "",
            max_players: 4,
            min_players: 2,
            max_rounds: 10,
            bot_count: 0,
            round_duration: 60_000,
            break_duration: 10_000,
            prompts: []

  @type t :: %__MODULE__{
          game_name: String.t(),
          max_players: non_neg_integer(),
          min_players: non_neg_integer(),
          max_rounds: non_neg_integer(),
          bot_count: non_neg_integer(),
          round_duration: non_neg_integer(),
          break_duration: non_neg_integer(),
          prompts: [%DrawingPrompt{}]
        }

  @doc """
  Creates a new game options struct with default values.
  """
  def new(attrs \\ []) do
    struct(__MODULE__, attrs)
  end
end
