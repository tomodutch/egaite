defmodule EgaiteWeb.GameHelpers do
  import Phoenix.LiveView
  alias Egaite.{Player, Game, GameSupervisor}

  def system_msg(body) do
    %{id: System.unique_integer([:positive]), body: body, name: "System"}
  end

  def tab_class(active, current) do
    base = "w-full text-center py-2 border-b-2"

    if active == current do
      base <> " border-blue-600 text-blue-600 font-semibold"
    else
      base <> " border-transparent text-gray-500 hover:text-gray-700"
    end
  end

  def maybe_start_game(game_id, player) do
    try do
      Game.add_player(game_id, %Player{id: player.id, name: player.name})
      :already_started
    catch
      :exit, {:noproc, _} ->
        {:ok, pid} = GameSupervisor.start_game(game_id, %Player{id: player.id, name: player.name})
        {:ok, pid}
    end
  end
end
