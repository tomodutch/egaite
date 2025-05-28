defmodule EgaiteWeb.StatusBannerComponent do
  use Phoenix.Component

  attr :game_started, :boolean,
    required: true,
    doc: "Indicates if the game has started"

  attr :is_artist, :boolean,
    required: true,
    doc: "Indicates if the current player is the artist"

  attr :word, :string,
    required: true,
    doc: "The word to be drawn by the artist"

  def game_status_banner(assigns) do
    ~H"""
    <div class="bg-blue-100 border border-blue-500 text-blue-800 font-bold p-2 text-center flex-shrink-0 h-12 sticky top-0 z-10">
      {cond do
        !@game_started -> "Waiting for the artist to start the game..."
        @is_artist -> "🎨 Draw: #{@word}"
        true -> "Guess in chat!"
      end}
    </div>
    """
  end
end
