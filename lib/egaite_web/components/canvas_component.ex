defmodule EgaiteWeb.CanvasComponent do
  use Phoenix.Component

  @moduledoc """
  A component for rendering a drawing canvas in the Egaite game.
  """
  @doc """
  Renders a canvas element for drawing in the game.
  """
  attr :canvas_id, :string,
    required: true,
    doc: "Unique ID for the canvas element"

  attr :game_id, :string,
    required: true,
    doc: "ID of the game to which this canvas belongs"

  attr :player_id, :string,
    required: true,
    doc: "ID of the player using the canvas"

  attr :player_name, :string,
    required: true,
    doc: "Name of the player using the canvas"

  attr :artist, :string,
    required: true,
    doc: "ID of the current artist player, used to identify the artist in the game"

  def canvas(assigns) do
    ~H"""
    <canvas
      id={@canvas_id}
      canvas-id={@canvas_id}
      phx-hook="Drawing"
      data-game-id={@game_id}
      data-player-id={@player_id}
      data-player-name={@player_name}
      data-artist={@artist}
      class="w-full h-full block border border-gray-300"
    />
    """
  end
end
