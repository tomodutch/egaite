defmodule EgaiteWeb.PlayersListComponent do
  use Phoenix.Component

  @moduledoc """
  A component to display the list of players in the game.
  It highlights the current artist player in the list.
  """
  @doc """
  Renders a list of players in the game, highlighting the current artist.
  ## Assigns
  - `:players`: List of players, each player is a map with `:id` and `:name` keys.
  - `:artist`: The ID of the current artist player, used to highlight the artist in the list.
  """

  attr :players, :list,
    required: true,
    doc: "List of players in the game, each player is a map with `:id` and `:name` keys"

  attr :artist, :boolean,
    required: true,
    doc: "The ID of the current artist player, used to highlight the artist in the list"

  attr :player_points, :map,
    default: %{},
    doc: "Map of player IDs to their points, used to display points next to each player"

  def players_list(assigns) do
    ~H"""
    <section class="flex flex-col p-4 bg-white h-full border-b border-gray-300">
      <h2 class="text-lg font-semibold mb-2">Players</h2>
      <ul class="flex-grow overflow-auto space-y-1">
        <%= for player <- @players do %>
          <li class="text-gray-700">
            <%= if player.id == @artist do %>
              🖌️ {player.name} -
              <span class="text-sm text-gray-500">
                🏆 {Map.get(@player_points, player.id, 0)} points
              </span>
            <% else %>
              {player.name} -
              <span class="text-sm text-gray-500">
                🏆 {Map.get(@player_points, player.id, 0)} points
              </span>
            <% end %>
          </li>
        <% end %>
      </ul>
    </section>
    """
  end
end
