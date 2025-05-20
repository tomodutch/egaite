defmodule Egaite.RulesTest do
  use ExUnit.Case
  alias Egaite.{Rules, Game, Player}

  test "can not start with 0 players" do
    {:ok, game_pid} = Game.start_link("game", %Player{id: "1"})
    {:ok, pid} = Rules.start_link(0, game_pid)
    assert {:ok, false} = Rules.ready_to_start?(pid)
  end

  test "can not start with 1 player" do
    {:ok, game_pid} = Game.start_link("game", %Player{id: "1"})
    {:ok, pid} = Rules.start_link(1, game_pid)
    assert {:ok, false} = Rules.ready_to_start?(pid)
  end

  test "can start with 2 players" do
    {:ok, game_pid} = Game.start_link("game", %Player{id: "1"})
    {:ok, pid} = Rules.start_link(2, game_pid)
    assert {:ok, true} = Rules.ready_to_start?(pid)
  end

  test "game loop" do
    {:ok, game_pid} = Game.start_link("game", %Player{id: "1"})
    {:ok, pid} = Rules.start_link(3, game_pid)
    assert :ok = Rules.start_round(pid)
  end
end
