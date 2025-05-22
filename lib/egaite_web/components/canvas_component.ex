defmodule EgaiteWeb.CanvasComponent do
  use Phoenix.Component

  def canvas(assigns) do
    ~H"""
    <canvas
      id="drawingCanvas"
      phx-hook="Drawing"
      data-game-id={@game_id}
      data-player-id={@player_id}
      data-player-name={@player_name}
      class="w-full h-full block border border-gray-300"
    />
    """
  end
end
