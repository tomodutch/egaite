defmodule EgaiteWeb.GameLive do
  require Logger
  use EgaiteWeb, :live_view
  alias Egaite.{GameSupervisor, Game, Player}

  def mount(%{"id" => game_id}, _session, socket) do
    try do
      {:ok, players} = Game.get_players(game_id)
      current_artist = Game.get_current_artist(game_id)

      {:ok,
       Phoenix.Component.assign(socket,
         game_id: game_id,
         players: Map.values(players),
         current_artist: current_artist
       )}
    catch
      :exit, {:noproc, _} ->
        raise EgaiteWeb.Fallback
    end
  end

  def handle_event("start", _params, socket) do
    game_id = socket.assigns.game_id
    Logger.info("Game #{socket.assigns.game_id} is about to start")
    Game.start(game_id)
    {:noreply, socket}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <h1>Game!</h1>

    <ul>
      <%= for player <- @players do %>
        <li>{player.name}</li>
      <% end %>
    </ul>

    <%= if @current_artist == @me.id do %>
      <button
        phx-click="start"
        type="button"
        class="text-white bg-blue-700 hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 font-medium rounded-full text-sm px-5 py-2.5 text-center me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
      >
        Start
      </button>
    <% end %>
    """
  end
end
