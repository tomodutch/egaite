defmodule EgaiteWeb.PlayersListComponent do
  use Phoenix.Component

  def players_list(assigns) do
    ~H"""
    <section class="flex flex-col p-4 bg-white h-full border-b border-gray-300">
      <h2 class="text-lg font-semibold mb-2">Players</h2>
      <ul class="flex-grow overflow-auto space-y-1">
        <%= for player <- @players do %>
          <%= if player.id == @artist do %>
            <li class="text-gray-700">🖌️ {player.name}</li>
          <% else %>
            <li class="text-gray-700">{player.name}</li>
          <% end %>
        <% end %>
      </ul>
    </section>
    """
  end
end
