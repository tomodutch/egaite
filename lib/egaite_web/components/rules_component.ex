defmodule EgaiteWeb.RulesComponent do
  use EgaiteWeb, :html

  def rules(assigns) do
    ~H"""
    <section class="mb-4 p-4">
      <h2 class="text-lg font-bold mb-2">Game Rules & Instructions</h2>
      <p class="mb-2">
        The artist draws, and everyone guesses in chat! Ready, set, draw! 🎨💬
      </p>
    </section>
    """
  end
end
