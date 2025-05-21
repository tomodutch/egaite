defmodule Egaite.GameTest do
  use ExUnit.Case
  doctest Egaite.Game

  alias Egaite.{Game, Player}

  setup do
    id = Integer.to_string(:erlang.unique_integer([:positive]))
    player1 = %Player{id: "1"}
    {:ok, game_pid} = Game.start_link(id, player1, 2)
    on_exit(fn ->
      if Process.alive?(game_pid), do: GenServer.stop(game_pid, :normal)
    end)

    %{id: id, player1: player1, game_pid: game_pid}
  end

  test "does not allow duplicate game IDs", %{id: id, player1: player1} do
    assert {:error, {:already_started, _pid}} = Game.start_link(id, player1)
  end

  test "allows players to join", %{id: id} do
    player2 = %Player{id: "2"}
    assert :ok = Game.add_player(id, player2)
    {:ok, players} = Game.get_players(id)
    assert Map.has_key?(players, player2.id)
  end

  test "player cannot join twice", %{id: id, player1: player1} do
    player_id = player1.id
    assert {:error, {:already_joined, ^player_id}} = Game.add_player(id, player1)
  end

  test "first player to join becomes the first artist", %{id: id, player1: player1} do
    assert Game.get_current_artist(id) == player1.id
  end

  test "multiple players can join and start game", %{id: id} do
    Game.add_player(id, %Player{id: "2"})
    Game.add_player(id, %Player{id: "3"})
    assert {:ok, _} = Game.start(id)
  end

  test "players can leave the game", %{id: id} do
    Game.add_player(id, %Player{id: 2})
    Game.remove_player(id, 2)
    {:ok, players} = Game.get_players(id)
    refute Map.has_key?(players, 2)
  end

  test "game cannot start with fewer than 2 players", %{id: id} do
    assert {:error, :not_enough_players} = Game.start(id)
  end

  test "basic game flow with guesses", %{id: id, game_pid: game_pid} do
    monitor_ref = Process.monitor(game_pid)
    player1 = %Player{id: "1"}
    player2 = %Player{id: "2"}

    # Game already started in setup
    Game.add_player(id, player2)
    {:ok, _} = Game.start(id)

    # Round 1: artist is player1
    assert {:error, :artist_can_not_guess} = Game.guess(id, player1.id, "cat")
    assert {:ok, :miss} = Game.guess(id, player2.id, "animal")
    assert {:ok, :hit} = Game.guess(id, player2.id, "cat")

    # Round 2: artist is player2
    assert {:error, :artist_can_not_guess} = Game.guess(id, player2.id, "cat")
    assert {:ok, :miss} = Game.guess(id, player1.id, "animal")
    assert {:ok, :hit} = Game.guess(id, player1.id, "cat")

    assert_receive {:DOWN, ^monitor_ref, :process, ^game_pid, _reason}, 1000

    refute Process.alive?(game_pid)
  end

  test "game should stop after all players left", %{id: id, game_pid: game_pid} do
    monitor_ref = Process.monitor(game_pid)
    player1 = %Player{id: "1"}

    # Game already started in setup
    Game.remove_player(id, player1.id)
    assert_receive {:DOWN, ^monitor_ref, :process, ^game_pid, _reason}, 1000

    refute Process.alive?(game_pid)
  end
end
