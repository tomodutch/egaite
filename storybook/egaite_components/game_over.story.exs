defmodule EgaiteWeb.GameOverStory do
  use PhoenixStorybook.Story, :component
  alias EgaiteWeb.GameOverComponent

  def function, do: &EgaiteWeb.GameOverComponent.game_over/1
  def render_source, do: :function
  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: []
      }
    ]
  end
end
