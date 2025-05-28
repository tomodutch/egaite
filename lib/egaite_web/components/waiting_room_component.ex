defmodule EgaiteWeb.WaitingRoomComponent do
  use Phoenix.Component
  import EgaiteWeb.RulesComponent

  attr :is_artist, :boolean,
    required: true,
    doc: "Indicates if the current player is the artist"

  def waiting_room(assigns) do
    ~H"""
    <div class="h-full pt-12 flex flex-col justify-center items-center overflow-auto px-4 text-center">
      <%= if @is_artist do %>
        <.rules />
        <button
          phx-click="start"
          type="button"
          class="bg-blue-600 text-white px-6 py-3 rounded hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-lg"
        >
          Start Game
        </button>
      <% else %>
        <p class="italic text-lg text-gray-700 max-w-xs mx-auto mt-4">
          <.rules />
        </p>
      <% end %>
    </div>
    """
  end
end
