defmodule EgaiteWeb.GamesListLive do
  use EgaiteWeb, :live_view
  require Logger
  alias Egaite.{Game, Games, GameSupervisor}

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, :refresh)

    socket =
      socket
      |> assign(:games, Games.list_active_games())
      |> assign(:full_screen, true)

    {:ok, socket}
  end

  def handle_info(:refresh, socket) do
    {:noreply, assign(socket, games: Games.list_active_games())}
  end

  def handle_event("new_game", _unsigned_params, socket) do
    {:noreply, push_navigate(socket, to: ~p(/games/create))}
  end

  def handle_event("join", %{"id" => game_id}, socket) do
    join_reply = {:noreply, push_navigate(socket, to: ~p(/games/#{game_id}))}

    case Game.add_player(game_id, socket.assigns.me) do
      {:ok, _} -> join_reply
      {:error, {:already_joined, _}} -> join_reply
    end
  end

  def render(assigns) do
    ~H"""
    <div class="relative min-h-screen bg-blue-50">
      <!-- Floating background doodles -->
      <div class="bg-floating-doodles fixed inset-0 pointer-events-none opacity-20"></div>

    <!-- Main content container -->
      <div class="relative z-10 px-4 py-8 max-w-5xl mx-auto space-y-16">

    <!-- Hero Header -->
        <header class="text-center space-y-4 max-w-xl mx-auto">
          <h1 class="text-5xl font-extrabold text-blue-800 tracking-tight">🎨 Egaite</h1>
          <p class="text-lg text-blue-600">A chaotic doodle guessing game</p>
        </header>
      </div>

      <section class="w-full bg-blue-100 py-16">
        <div class="max-w-6xl mx-auto px-6">
          <div class="grid grid-cols-1 md:grid-cols-2 items-center gap-12">

    <!-- Left: Game Rules aligned with cards -->
            <div class="text-blue-800 space-y-4 text-center md:text-left max-w-md">
              <h2 class="text-4xl font-bold">How to Play</h2>
              <ul class="list-disc list-inside text-blue-700 space-y-2">
                <li>Draw a word you’re given.</li>
                <li>Guess what others drew.</li>
                <li>Laugh at the chaos.</li>
              </ul>
              <p class="text-sm text-blue-500 italic">It’s like telephone, but with doodles!</p>
            </div>

    <!-- Right: Gameplay GIF -->
            <div class="flex justify-center">
              <img
                src="/images/banner-doodle.png"
                alt="Gameplay preview"
                class="w-full max-w-md rounded-lg shadow-lg"
              />
            </div>
          </div>
        </div>
      </section>

    <!-- Game List Section -->
      <div class="relative z-10 px-4 py-16 max-w-6xl mx-auto">
        <section>
          <h2 class="text-2xl font-semibold text-blue-800 mb-6">Available Games</h2>

          <%= if @games == [] do %>
            <p class="text-center text-blue-400 italic">No games available at the moment.</p>
          <% else %>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for game <- @games do %>
                <div
                  phx-click="join"
                  phx-value-id={game}
                  class="bg-white border border-blue-100 hover:border-blue-300 rounded-xl shadow-md hover:shadow-xl transition p-6 cursor-pointer group flex flex-col justify-between"
                >
                  <div>
                    <div class="flex items-center justify-between mb-2">
                      <h3 class="text-blue-800 font-semibold truncate max-w-xs">
                        Game ID: {game}
                      </h3>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-5 w-5 text-blue-300 group-hover:text-blue-500 transition"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        stroke-width="2"
                      >
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                      </svg>
                    </div>
                    <p class="text-sm text-blue-600 mb-1">Players: 0</p>
                    <p class="text-xs text-blue-400 italic">
                      Started {format_started_time(DateTime.utc_now())}
                    </p>
                  </div>

                  <p class="mt-4 text-right text-sm text-blue-400 group-hover:text-blue-600 transition">
                    Tap to join →
                  </p>
                </div>
              <% end %>
            </div>
          <% end %>
        </section>
      </div>

    <!-- Create Game Button -->
      <button
        phx-click="new_game"
        class="group fixed bottom-6 right-6 bg-blue-500 hover:bg-blue-600 text-white rounded-full shadow-lg flex items-center gap-3 px-5 py-3 text-base font-semibold transition z-50 focus:outline-none focus:ring-2 focus:ring-blue-300"
        aria-label="Start a new game"
      >
        <span class="text-xl">🎨</span>
        <span class="hidden sm:inline">Create Game</span>
      </button>
    </div>
    """
  end

  defp format_started_time(nil), do: "not started"

  defp format_started_time(datetime) do
    minutes_ago = DateTime.diff(DateTime.utc_now(), datetime, :minute)

    if minutes_ago <= 1 do
      "just now"
    else
      "#{minutes_ago} minutes ago"
    end
  end
end
