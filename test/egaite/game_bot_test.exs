defmodule Egaite.GameBotTest do
  use ExUnit.Case, async: true
  import Egaite.TestHelpers
  alias Egaite.{Game, Player, GameSupervisor, GameBot, GameOptions}

  setup do
    game_id = Ecto.UUID.generate()
    player = %Player{id: "bot_player", name: "Bot Player"}
    options = %GameOptions{max_rounds: 3, max_players: 1, bot_count: 2}
    {:ok, _pid} = GameSupervisor.start_game(game_id, player, options)
    %{game_id: game_id, player: player, options: options}
  end

  test "bots should start with the game", %{game_id: game_id, options: options} do
    assert_eventually do
      {:ok, players} = Game.get_players(game_id)
      assert Kernel.map_size(players) == options.bot_count + 1
    end
  end

  test "bots should have unique names", %{game_id: game_id, options: options} do
    assert_eventually do
      {:ok, players} = Game.get_players(game_id)
      names = Enum.map(players, fn {_, player} -> player.name end)
      assert length(names) == length(Enum.uniq(names))
    end
  end

  test "should be able to start a game with enough bots", %{game_id: game_id, options: options} do
    assert_eventually do
      assert Game.ready_to_start?(game_id)
    end
  end
end
