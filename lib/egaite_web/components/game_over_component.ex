defmodule EgaiteWeb.GameOverComponent do
  use Phoenix.Component

  attr :players, :list,
    default: [],
    doc: "List of players in the game, used to display player names at the end of the game"

  attr :points, :map,
    default: %{},
    doc: "Map of player IDs to their points, used to display points at the end of the game"

  def game_over(assigns) do
    sorted_players =
      Enum.sort_by(
        assigns.players,
        fn player ->
          Map.get(assigns.points, player.id, 0)
        end,
        :desc
      )

    ~H"""
    <div class="flex flex-col justify-center items-center h-full text-center p-4">
      <h2 class="text-2xl font-bold text-gray-800 mb-4">Game Over 🎉</h2>
      <p class="text-gray-600 mb-4">
        Thanks for playing!
        <ol>
          <%= for {player, i} <- Enum.with_index(sorted_players) do %>
            <li class="mb-2">
              <span class="font-semibold">{trophy_emoji(i)} {player.name}</span>
              - <span class="text-gray-500">{Map.get(@points, player.id, 0)} points</span>
            </li>
          <% end %>
        </ol>
      </p>
      <a href="/" class="text-blue-600 hover:underline">Return to lobby</a>
    </div>
    """
  end

  defp trophy_emoji(0), do: "🥇"
  defp trophy_emoji(1), do: "🥈"
  defp trophy_emoji(2), do: "🥉"
  defp trophy_emoji(_), do: ""
end
