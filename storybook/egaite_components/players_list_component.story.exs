defmodule EgaiteWeb.PlayersListComponentStory do
  use PhoenixStorybook.Story, :component
  alias EgaiteWeb.PlayersListComponent

  def function, do: &PlayersListComponent.players_list/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          players: [
            %{id: "1", name: "Alice", score: 10},
            %{id: "2", name: "Bob", score: 20},
            %{id: "3", name: "Charlie", score: 15}
          ],
          player_points: %{
            "1" => 10,
            "2" => 20,
            "3" => 15
          },
          artist: "1"
        },
        slots: []
      },
      %Variation{
        id: :empty,
        attributes: %{
          players: []
        },
        slots: []
      }
    ]
  end
end
