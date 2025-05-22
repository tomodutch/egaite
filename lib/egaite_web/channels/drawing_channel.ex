defmodule EgaiteWeb.DrawingChannel do
  use EgaiteWeb, :channel

  @impl true
  def join("drawing:" <> _game_id, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("draw", %{"x" => x, "y" => y}, socket) do
    broadcast_from!(socket, "draw", %{x: x, y: y})
    {:noreply, socket}
  end

  @impl true
  def handle_in("draw_batch", points, socket) do
    broadcast_from!(socket, "draw_batch", points)

    {:noreply, socket}
  end

  @impl true
  def handle_in("drawing_image", %{"image" => base64_image}, socket) do
    broadcast_from(socket, "drawing_image", %{"image" => base64_image})
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (drawing:lobby).
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
