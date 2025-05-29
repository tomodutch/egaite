defmodule Egaite.GameSupervisor do
  use DynamicSupervisor
  alias Egaite.GameOptions

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def start_game(game_id, player, opts \\ %GameOptions{}) do
    child_spec = {Egaite.Game, {game_id, player, opts}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)
end
