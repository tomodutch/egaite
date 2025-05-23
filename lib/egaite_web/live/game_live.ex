defmodule EgaiteWeb.GameLive do
  require Logger
  use EgaiteWeb, :live_view
  alias Egaite.{GameSupervisor, Game, Player}
  import EgaiteWeb.{CanvasComponent, PlayersListComponent, ChatBoxComponent}

  def mount(%{"id" => game_id}, _session, socket) do
    try do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Egaite.PubSub, "game:#{game_id}")
        Phoenix.PubSub.subscribe(Egaite.PubSub, "chat:#{game_id}")
      end

      {:ok, players} = Game.get_players(game_id)
      current_artist = Game.get_current_artist(game_id)

      {:ok,
       assign(socket,
         game_id: game_id,
         players: Map.values(players),
         current_artist: current_artist,
         game_started: false,
         full_screen: true
       )
       |> stream(:messages, [])}
    catch
      :exit, {:noproc, _} ->
        {:ok, _pid} =
          GameSupervisor.start_game(game_id, %Player{
            id: socket.assigns.me.id,
            name: socket.assigns.me.name
          })

        {:ok, players} = Game.get_players(game_id)
        current_artist = Game.get_current_artist(game_id)

        {:ok,
         assign(socket,
           game_id: game_id,
           players: Map.values(players),
           current_artist: current_artist,
           game_started: false,
           full_screen: true
         )
         |> stream(:messages, [])}
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

    {:noreply, socket |> assign(game_started: true) |> stream_insert(:messages, msg)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    game_id = socket.assigns.game_id

    # Re-fetch the latest list of players
    {:ok, players} = Game.get_players(game_id)

    {:noreply, assign(socket, players: Map.values(players))}
  end

  def handle_event("start", _params, socket) do
    game_id = socket.assigns.game_id
    Logger.info("Game #{socket.assigns.game_id} is about to start")
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

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
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
      <!-- Canvas Area -->
      <main class="w-full md:w-[60vw] h-[50vh] md:h-full border-b md:border-b-0 md:border-r border-gray-300">
        <.canvas game_id={@game_id} player_id={@me.id} player_name={@me.name} />
      </main>

    <!-- Sidebar: Players + Chat -->
      <aside class="w-full md:w-[40vw] max-w-full md:max-w-[40vw] flex flex-col h-full overflow-hidden">
        <.players_list players={@players} />
        <.chat_box messages={@streams.messages} />
      </aside>

    <!-- Game State / Button -->
      <%= if @game_started do %>
        <div class="absolute top-4 left-4 bg-green-100 text-green-800 px-3 py-1 rounded shadow">
          Game started
        </div>
      <% else %>
        <%= if @current_artist == @me.id do %>
          <button
            phx-click="start"
            type="button"
            class="absolute bottom-4 left-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            Start
          </button>
        <% end %>
      <% end %>
    </div>
    """
  end
end
