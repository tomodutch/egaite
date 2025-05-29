defmodule EgaiteWeb.GamePresenceChannelTest do
  use EgaiteWeb.ChannelCase
  import Egaite.TestHelpers

  setup do
    topic = "game_presence:1"

    {:ok, _, socket} =
      EgaiteWeb.UserSocket
      |> socket("socket", %{})
      |> subscribe_and_join(EgaiteWeb.GamePresenceChannel, topic, %{
        "player_id" => "1"
      })

    %{socket: socket, topic: topic}
  end

  test "presence list is updated on join", %{topic: topic} do
    assert_eventually do
      presences = EgaiteWeb.Presence.list(topic)
      map_size(presences) == 1
    end
  end
end
