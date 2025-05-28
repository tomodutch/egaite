defmodule EgaiteWeb.GameOverComponent do
  use Phoenix.Component

  def game_over(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center h-full text-center p-4">
      <h2 class="text-2xl font-bold text-gray-800 mb-4">Game Over 🎉</h2>
      <p class="text-gray-600 mb-4">
        Thanks for playing!
      </p>
      <a href="/" class="text-blue-600 hover:underline">Return to lobby</a>
    </div>
    """
  end
end
