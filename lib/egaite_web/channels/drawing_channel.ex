defmodule EgaiteWeb.DrawingChannel do
  use EgaiteWeb, :channel

  @impl true
  def join("drawing:" <> _game_id, payload, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_in("draw_batch", points, socket) do
    broadcast_from!(socket, "draw_batch", points)

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{
          "event" => "clear_canvas",
          "artist" => artist
        },
        socket
      ) do
    broadcast_from(socket, "clear_canvas", %{
      artist: artist
    })

    {:noreply, socket}
  end
end
