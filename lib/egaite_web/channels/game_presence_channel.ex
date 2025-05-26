defmodule EgaiteWeb.GamePresenceChannel do
  use EgaiteWeb, :channel
  alias EgaiteWeb.Presence
  alias Egaite.Game
  require Logger

  @impl true
  def join(
        "game_presence:" <> game_id,
        %{"player_id" => player_id},
        socket
      ) do
    send(self(), :after_join)

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(:player_id, player_id)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Presence will automatically track and broadcast presence_diff events
    {:ok, _} =
      Presence.track(
        socket,
        socket.assigns.player_id,
        %{joined_at: System.system_time(:second)}
      )

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{leaves: leaves}}, socket) do
    # This only gets called if the diff is broadcast to the topic we're subscribed to
    game_id = socket.assigns.game_id

    for {player_id, _meta} <- leaves do
      Game.remove_player(game_id, player_id)
    end

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    # Fallback cleanup — but not reliable, since browser close doesn’t guarantee it
    if Map.has_key?(socket.assigns, :game_id) do
      Game.remove_player(socket.assigns.game_id, socket.assigns.player_id)
    end

    :ok
  end
end
