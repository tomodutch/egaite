defmodule EgaiteWeb.GameChannel do
  require Logger
  use EgaiteWeb, :channel
  alias Egaite.{Player, Game}
  alias EgaiteWeb.Presence

  @impl true
  def join("game:" <> game_id, %{"player_id" => player_id, "player_name" => player_name}, socket) do
    case Game.add_player(game_id, %Player{id: player_id, name: player_name}) do
      {:error, {:already_joined, _}} ->
        send(self(), :after_join)

        {:ok,
         socket
         |> assign(:game_id, game_id)
         |> assign(:player_id, player_id)
         |> assign(:player_name, player_name)}

      {:ok, _} ->
        send(self(), :after_join)

        {:ok,
         socket
         |> assign(:game_id, game_id)
         |> assign(:player_id, player_id)
         |> assign(:player_name, player_name)}

      {:error, reason} ->
        Logger.error("could not join #{reason}")
        {:error, %{reason: "Could not join game"}}

      _ ->
        {:error, %{reason: "Could not join game"}}
    end
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
  def handle_info(%{event: "game_started"}, socket) do
    push(socket, "game_started", %{})
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if Map.has_key?(socket.assigns, :game_id) do
      Game.remove_player(socket.assigns.game_id, socket.assigns.player_id)
    end

    :ok
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
