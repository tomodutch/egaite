defmodule EgaiteWeb.GameLive do
  use EgaiteWeb, :live_view
  require Logger
  alias Egaite.{GameSupervisor, Game, Player}
  import EgaiteWeb.{CanvasComponent, PlayersListComponent, ChatBoxComponent, RulesComponent}

  def mount(%{"id" => game_id}, _session, socket) do
    try do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Egaite.PubSub, "game:#{game_id}")
        Phoenix.PubSub.subscribe(Egaite.PubSub, "chat:#{game_id}")
      end

      {:ok, players} = Game.get_players(game_id)
      current_artist = Game.get_current_artist(game_id)

      socket =
        socket
        |> assign(:game_id, game_id)
        |> assign(:game_started, false)
        |> assign(:players, Map.values(players))
        |> assign(:current_artist, current_artist)
        |> assign(:full_screen, true)
        |> stream(:messages, [])

      {:ok, socket}
    catch
      :exit, {:noproc, _} ->
        {:ok, _pid} =
          GameSupervisor.start_game(game_id, %Player{
            id: socket.assigns.me.id,
            name: socket.assigns.me.name
          })

        {:ok, players} = Game.get_players(game_id)
        current_artist = Game.get_current_artist(game_id)

        socket =
          socket
          |> assign(:game_id, game_id)
          |> assign(:game_started, false)
          |> assign(:players, Map.values(players))
          |> assign(:current_artist, current_artist)
          |> assign(:full_screen, true)
          |> stream(:messages, [])

        {:ok, socket}
    end
  end

  def handle_info(%{event: "game_started"}, socket) do
    {:noreply, assign(socket, game_started: true)}
  end

  def handle_info(%{"event" => "round_started", "artist" => artist}, socket) do
    Logger.info("round over!")

    msg = %{
      id: System.unique_integer([:positive]),
      body: "Starting next round",
      name: "System"
    }

    {:noreply,
     socket
     |> assign(game_started: true)
     |> assign(current_artist: artist)
     |> stream_insert(:messages, msg)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    game_id = socket.assigns.game_id

    # Re-fetch the latest list of players
    {:ok, players} = Game.get_players(game_id)

    {:noreply, assign(socket, players: Map.values(players))}
  end

  def handle_event("start", _params, socket) do
    game_id = socket.assigns.game_id
    Logger.info("Game #{game_id} is about to start")
    Game.start(game_id)
    Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{game_id}", %{event: "game_started"})
    {:noreply, socket}
  end

  def handle_event("send_message", %{"body" => body}, socket) do
    if String.trim(body) != "" do
      msg = %{
        id: System.unique_integer([:positive]),
        body: body,
        name: socket.assigns.me.name
      }

      Phoenix.PubSub.broadcast(
        Egaite.PubSub,
        "chat:#{socket.assigns.game_id}",
        {:new_message, msg}
      )

      case Game.guess(socket.assigns.game_id, socket.assigns.me.id, body) do
        {:ok, :hit} ->
          {:noreply,
           socket
           |> stream_insert(:messages, %{
             id: System.unique_integer([:positive]),
             body: "#{socket.assigns.me.name} guessed the word!",
             name: "System"
           })
           |> stream_insert(:messages, msg)}

        {:ok, :miss} ->
          {:noreply, stream_insert(socket, :messages, msg)}

        {:error, :artist_can_not_guess} ->
          {:noreply, stream_insert(socket, :messages, msg)}

        {:error, :word_not_set} ->
          {:noreply, stream_insert(socket, :messages, msg)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_info({:new_message, msg}, socket) do
    {:noreply, stream_insert(socket, :messages, msg)}
  end

  defp waiting_room(assigns) do
    ~H"""
    <div class="relative flex flex-col h-full justify-between">
      <.canvas game_id={@game_id} player_id={@me.id} player_name={@me.name} artist={nil} />

      <%= if @current_artist == @me.id do %>
        <!-- Overlay for artist with rules and start button -->
        <div
          class="absolute inset-0 flex flex-col items-center justify-center bg-black bg-opacity-70 text-white z-10 p-6"
          style="pointer-events:auto;"
        >
          <div class="max-w-lg w-full mb-6">
            <.rules />
          </div>

          <button
            phx-click="start"
            type="button"
            class="bg-blue-600 text-white px-6 py-3 rounded hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            Start Game
          </button>
        </div>
      <% else %>
        <div class="absolute inset-0 flex flex-col items-center justify-center bg-black bg-opacity-30 text-white text-center z-10 p-6 pointer-events-none">
          <div class="max-w-lg w-full mb-4">
            <.rules />
          </div>
          <p class="italic text-lg">Waiting for the artist to start the game...</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp game_canvas(assigns) do
    ~H"""
    <.canvas game_id={@game_id} player_id={@me.id} player_name={@me.name} artist={@current_artist} />
    """
  end

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div
      id="game-presence"
      phx-hook="GamePresence"
      data-game-id={@game_id}
      data-player-id={@me.id}
      data-player-name={@me.name}
      class="flex flex-col md:flex-row h-screen bg-white"
    >
      <!-- Left: Canvas Section -->
      <main class="w-full md:w-[60%] h-1/2 md:h-full border-b md:border-b-0 md:border-r border-gray-300 p-4 overflow-auto">
        <%= if @game_started do %>
          {game_canvas(assigns)}
        <% else %>
          {waiting_room(assigns)}
        <% end %>
      </main>

    <!-- Right: Players and Chat -->
      <aside class="w-full md:w-[40%] h-1/2 md:h-full flex flex-col">
        <!-- Players -->
        <div class="h-1/2 overflow-auto border-b border-gray-300">
          <.players_list players={@players} artist={@current_artist} />
        </div>

    <!-- Chat -->
        <div class="h-1/2 overflow-auto">
          <.chat_box messages={@streams.messages} />
        </div>
      </aside>
    </div>
    """
  end
end
