defmodule EgaiteWeb.StatusBannerComponentStory do
  use PhoenixStorybook.Story, :component
  def function, do: &EgaiteWeb.StatusBannerComponent.game_status_banner/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :waiting_for_artist,
        attributes: %{
          game_started: false,
          is_artist: false,
          word: ""
        },
        slots: []
      },
      %Variation{
        id: :artist_turn,
        attributes: %{
          game_started: true,
          is_artist: true,
          word: "apple"
        },
        slots: []
      },
      %Variation{
        id: :guessing_turn,
        attributes: %{
          game_started: true,
          is_artist: false,
          word: "banana"
        },
        slots: []
      },
      %Variation{
        id: :game_over,
        attributes: %{
          game_ended: true,
          game_started: false,
          is_artist: false,
          word: "banana"
        },
        slots: []
      }
    ]
  end
end
