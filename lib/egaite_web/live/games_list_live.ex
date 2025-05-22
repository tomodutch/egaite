defmodule EgaiteWeb.GamesListLive do
  use EgaiteWeb, :live_view
  require Logger
  alias Egaite.{Game, Games, GameSupervisor}

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, :refresh)
    {:ok, assign(socket, games: Games.list_active_games())}
  end

  def handle_info(:refresh, socket) do
    {:noreply, assign(socket, games: Games.list_active_games())}
  end

  def handle_event("new", _unsigned_params, socket) do
    game_id = Ecto.UUID.generate()
    GameSupervisor.start_game(game_id, socket.assigns.me)
    {:noreply, push_navigate(socket, to: ~p(/games/#{game_id}))}
  end

  def handle_event("join", %{"game-id" => game_id}, socket) do
    join_reply = {:noreply, push_navigate(socket, to: ~p(/games/#{game_id}))}

    case Game.add_player(game_id, socket.assigns.me) do
      {:ok, _} -> join_reply
      {:error, {:already_joined, _}} -> join_reply
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Active Games</h1>
    <table>
      <thead>
        <tr>
          <th>Game</th>
          <th></th>
        </tr>
      </thead>
      <%= for game_id <- @games do %>
        <tr>
          <td>{game_id}</td>
          <td>
            <button phx-click="join" phx-value-game-id={game_id}>join</button>
          </td>
        </tr>
      <% end %>
    </table>

    <button phx-click="new">create a game</button>
    """
  end
end
