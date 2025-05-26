defmodule EgaiteWeb.GamePresenceChannel do
  use EgaiteWeb, :channel
  alias EgaiteWeb.Presence
  alias Egaite.Game

  @impl true
  def join(
        "game_presence:" <> game_id,
        %{"player_id" => player_id, "player_name" => player_name},
        socket
      ) do
    send(self(), :after_join)

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(:player_id, player_id)
     |> assign(:player_name, player_name)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    Presence.track(
      socket,
      socket.assigns.player_id,
      %{joined_at: System.system_time(:second)}
    )

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if Map.has_key?(socket.assigns, :game_id) do
      Game.remove_player(socket.assigns.game_id, socket.assigns.player_id)
    end

    :ok
  end
end
