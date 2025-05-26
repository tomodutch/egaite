defmodule EgaiteWeb.RulesComponent do
  use EgaiteWeb, :html

  def rules(assigns) do
    ~H"""
    <section class="mb-4 p-4 border rounded relative">
      <h2 class="text-lg font-bold mb-2">Game Rules & Instructions</h2>
      <p class="mb-2">
        Welcome to the game! The artist will draw a word, and other players try to guess it by chatting.
        When you are the artist, start the game and draw your word on the canvas.
      </p>
      <p class="mb-2">
        Players can chat and guess anytime. The first correct guess wins the round!
      </p>
    </section>
    """
  end
end
