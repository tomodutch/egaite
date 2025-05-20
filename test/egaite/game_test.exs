defmodule Egaite.GameTest do
  use ExUnit.Case
  doctest Egaite.Game

  alias Egaite.{Game, Player}

  setup do
    id = "1"
    player1 = %Player{id: "1"}
    {:ok, _pid} = Game.start_link(id, player1)
    %{id: id, player1: player1}
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

  test "players can leave the game", %{id: id, player1: player1} do
    Game.remove_player(id, player1.id)
    {:ok, players} = Game.get_players(id)
    refute Map.has_key?(players, player1.id)
  end

  test "game cannot start with fewer than 2 players", %{id: id} do
    assert {:error, :not_enough_players} = Game.start(id)
  end

  test "basic game flow with guesses", %{id: id} do
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
  end
end
