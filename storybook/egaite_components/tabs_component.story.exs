defmodule EgaiteWeb.TabsComponentStory do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.TabsComponent.tabs_component/1
  def render_source, do: :function

  def variations() do
    [
      %Variation{
        id: :chat_tab,
        attributes: %{
          active_tab: "chat",
          players: [],
          current_artist: nil,
          messages: []
        },
        slots: []
      },
      %Variation{
        id: :players_tab,
        attributes: %{
          active_tab: "players",
          players: [],
          current_artist: nil,
          messages: []
        },
        slots: []
      },
      %Variation{
        id: :rules_tab,
        attributes: %{
          active_tab: "rules",
          players: [],
          current_artist: nil,
          messages: []
        },
        slots: []
      }
    ]
  end
end
