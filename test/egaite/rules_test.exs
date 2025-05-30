defmodule Egaite.RulesTest do
  use ExUnit.Case
  alias Egaite.{Rules, Game, Player, GameOptions}

  test "can not start with 0 players" do
    {:ok, game_pid} = Game.start_link("game", %Player{id: "1"}, %GameOptions{max_rounds: 8})
    {:ok, pid} = Rules.start_link(0, game_pid)
    assert {:ok, false} = Rules.ready_to_start?(pid)
  end

  test "can not start with 1 player" do
    {:ok, game_pid} = Game.start_link("game", %Player{id: "1"}, %GameOptions{max_rounds: 8})
    {:ok, pid} = Rules.start_link(1, game_pid)
    assert {:ok, false} = Rules.ready_to_start?(pid)
  end

  test "can start with 2 players" do
    {:ok, game_pid} = Game.start_link("game", %Player{id: "1"}, %GameOptions{max_rounds: 8})
    {:ok, pid} = Rules.start_link(2, game_pid)
    assert {:ok, true} = Rules.ready_to_start?(pid)
  end

  test "game loop" do
    {:ok, game_pid} = Game.start_link("game", %Player{id: "1"}, %GameOptions{max_rounds: 8})
    {:ok, pid} = Rules.start_link(3, game_pid)
    assert {:ok, true} = Rules.ready_to_start?(pid)
    assert {:ok, 1, 8} = Rules.start_round(pid)
  end

  test "stop game when 0 players" do
    {:ok, rules_pid} = Rules.start_link(1, self())
    Rules.set_player_count(rules_pid, 0)
    assert {:game_over, _} = :sys.get_state(rules_pid)
    assert_receive :game_over, 1000
  end
end
