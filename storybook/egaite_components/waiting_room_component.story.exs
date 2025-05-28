defmodule EgaiteWeb.WaitingRoomComponentStory do
  use PhoenixStorybook.Story, :component
  def function, do: &EgaiteWeb.WaitingRoomComponent.waiting_room/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :waiting_is_artist,
        attributes: %{
          is_artist: true
        },
        slots: []
      },
      %Variation{
        id: :waiting_not_artist,
        attributes: %{
          is_artist: false
        },
        slots: []
      }
    ]
  end
end
