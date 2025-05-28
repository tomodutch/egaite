defmodule EgaiteWeb.CanvasComponentStory do
  use PhoenixStorybook.Story, :component
  alias EgaiteWeb.CanvasComponent

  def function, do: &CanvasComponent.canvas/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          canvas_id: "drawingCanvas",
          game_id: "game123",
          player_id: "player456",
          player_name: "ArtistName",
          artist: "player456"
        },
        slots: []
      },
      %Variation{
        id: :empty,
        attributes: %{
          canvas_id: "drawingCanvasEmpty",
          game_id: "",
          player_id: "",
          player_name: "",
          artist: ""
        },
        slots: []
      }
    ]
  end
end
