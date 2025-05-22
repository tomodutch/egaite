defmodule EgaiteWeb.PlayersListComponent do
  use Phoenix.Component

  def players_list(assigns) do
    ~H"""
    <section class="p-4 border-b border-gray-300 bg-white">
      <h2 class="text-lg font-semibold mb-2">Players</h2>
      <ul class="space-y-1 max-h-40 overflow-auto">
        <%= for player <- @players do %>
          <li class="text-gray-700"><%= player.name %></li>
        <% end %>
      </ul>
    </section>
    """
  end
end
