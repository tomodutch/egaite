defmodule Egaite.GameTest do
  use ExUnit.Case
  doctest Egaite.Game
  import Egaite.TestHelpers

  alias Egaite.{Game, Player, GameOptions}

  setup do
    id = Integer.to_string(:erlang.unique_integer([:positive]))
    player1 = %Player{id: "1"}
    player2 = %Player{id: "2"}
    {:ok, game_pid} = Game.start_link(id, player1, GameOptions.new(max_rounds: 2))

    :ok = Phoenix.PubSub.subscribe(Egaite.PubSub, "game:#{id}")
    monitor_ref = Process.monitor(game_pid)

    on_exit(fn ->
      if Process.alive?(game_pid), do: GenServer.stop(game_pid, :normal)
    end)

    %{
      id: id,
      game_pid: game_pid,
      player1: player1,
      player2: player2,
      monitor_ref: monitor_ref
    }
  end

  describe "game lifecycle" do
    test "does not allow duplicate game IDs", %{id: id, player1: player1} do
      assert {:error, {:already_started, _pid}} = Game.start_link(id, player1, GameOptions.new())
    end

    test "game cannot start with fewer than 2 players", %{id: id} do
      assert {:error, :not_enough_players} = Game.start(id)
    end

    test "multiple players can join and start game", %{id: id, player2: player2} do
      :ok = Game.add_player(id, player2)
      assert {:ok, _} = Game.start(id)
    end

    test "players can leave the game", %{id: id} do
      player2 = %Player{id: "2"}
      :ok = Game.add_player(id, player2)
      Game.remove_player(id, player2.id)
      {:ok, players} = Game.get_players(id)
      refute Map.has_key?(players, player2.id)
    end
  end

  describe "player management" do
    test "allows players to join", %{id: id, player2: player2} do
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

    test "adding player updates points", %{id: id} do
      new_player = %Player{id: "3"}
      Game.add_player(id, new_player)
      {:ok, points} = Game.get_points(id)
      assert Map.get(points, new_player.id) == 0
    end

    test "Removing player should not update points", %{id: id} do
      new_player = %Player{id: "3"}
      Game.add_player(id, new_player)
      Game.remove_player(id, new_player.id)
      {:ok, points} = Game.get_points(id)
      assert Map.get(points, new_player.id) == 0
    end
  end

  describe "game start events" do
    setup %{id: id, player2: player2} do
      :ok = Game.add_player(id, player2)
      :ok
    end

    test "game starts and sends game_started event", %{id: id} do
      {:ok, word} = Game.start(id)

      assert_eventually do
        assert_receive %{"event" => "game_started", "artist" => _, "word_to_draw" => ^word}
      end
    end
  end

  describe "guessing logic" do
    setup %{id: id, player2: player2} do
      :ok = Game.add_player(id, player2)
      {:ok, _word} = Game.start(id)
      :ok
    end

    test "artist cannot guess the word in round 1", %{id: id, player1: artist, player2: player2} do
      {:ok, word} = Game.get_current_word(id)
      assert {:error, :artist_can_not_guess} = Game.guess(id, artist.id, word)
    end

    test "other player misses then hits the correct word", %{id: id, player2: guesser} do
      {:ok, word} = Game.get_current_word(id)
      assert {:ok, :miss} = Game.guess(id, guesser.id, "animal")
      assert {:ok, :hit} = Game.guess(id, guesser.id, word)
    end

    test "both guesser and artist get point for correct guess", %{
      id: id,
      player1: artist,
      player2: guesser
    } do
      {:ok, word} = Game.get_current_word(id)
      assert {:ok, :hit} = Game.guess(id, guesser.id, word)
      artist_id = artist.id
      guesser_id = guesser.id
      assert {:ok, %{^guesser_id => 1, ^artist_id => 1}} = Game.get_points(id)
    end

    test "round 2 starts with new artist and new word", %{id: id, player2: guesser} do
      {:ok, old_word} = Game.get_current_word(id)
      {:ok, :hit} = Game.guess(id, guesser.id, old_word)

      assert_eventually do
        assert_receive %{
          "event" => "round_started",
          "word_to_draw" => new_word
        }

        refute old_word == new_word
      end
    end

    test "round 2: artist cannot guess and other player guesses correctly", %{
      id: id,
      player1: player1,
      player2: player2
    } do
      {:ok, old_word} = Game.get_current_word(id)
      {:ok, :hit} = Game.guess(id, player2.id, old_word)

      new_word =
        assert_eventually do
          assert_receive %{"event" => "round_started", "word_to_draw" => word}
          word
        end

      assert {:error, :artist_can_not_guess} = Game.guess(id, player2.id, new_word)
      assert {:ok, :miss} = Game.guess(id, player1.id, "animal")
      assert {:ok, :hit} = Game.guess(id, player1.id, new_word)
    end
  end

  describe "game process lifecycle" do
    test "basic game flow with guesses", %{
      id: id,
      game_pid: game_pid,
      player1: player1,
      player2: player2,
      monitor_ref: monitor_ref
    } do
      Game.add_player(id, player2)
      {:ok, word} = Game.start(id)

      assert_eventually do
        assert_receive %{"event" => "game_started", "artist" => _, "word_to_draw" => ^word}
      end

      # Round 1: artist is player1
      assert {:error, :artist_can_not_guess} = Game.guess(id, player1.id, word)
      assert {:ok, :miss} = Game.guess(id, player2.id, "animal")
      assert {:ok, :hit} = Game.guess(id, player2.id, word)

      new_word =
        assert_eventually do
          assert_receive %{
            "event" => "round_started",
            "word_to_draw" => word
          }

          word
        end

      # Round 2: artist is player2
      assert {:error, :artist_can_not_guess} = Game.guess(id, player2.id, new_word)
      assert {:ok, :miss} = Game.guess(id, player1.id, "animal")
      assert {:ok, :hit} = Game.guess(id, player1.id, new_word)

      assert_receive {:DOWN, ^monitor_ref, :process, ^game_pid, _reason}, 1000
      refute Process.alive?(game_pid)
    end

    test "game should stop after all players left", %{
      id: id,
      game_pid: game_pid,
      player1: player1,
      monitor_ref: monitor_ref
    } do
      Game.remove_player(id, player1.id)

      assert_receive {:DOWN, ^monitor_ref, :process, ^game_pid, _reason}, 1000
      refute Process.alive?(game_pid)
    end
  end
end
