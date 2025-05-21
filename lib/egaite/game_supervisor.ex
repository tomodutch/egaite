defmodule Egaite.GameSupervisor do
  use DynamicSupervisor

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def start_game(game_id, player) do
    child_spec = {Egaite.Game, {game_id, player}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)
end
