defmodule EgaiteWeb.GameOverStory do
  use PhoenixStorybook.Story, :component
  alias EgaiteWeb.GameOverComponent

  def function, do: &EgaiteWeb.GameOverComponent.game_over/1
  def render_source, do: :function
  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          players: [
            %{id: "1", name: "Alice"},
            %{id: "2", name: "Bob"},
            %{id: "3", name: "Charlie"},
            %{id: "4", name: "Jane"}
          ],
          points: %{
            "1" => 10,
            "2" => 20,
            "3" => 15,
            "4" => 2
          }
        },
        slots: []
      }
    ]
  end
end
