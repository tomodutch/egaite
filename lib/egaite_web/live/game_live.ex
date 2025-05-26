defmodule EgaiteWeb.GameLive do
  use EgaiteWeb, :live_view
  require Logger
  alias Egaite.{GameSupervisor, Game, Player}
  import EgaiteWeb.{CanvasComponent, PlayersListComponent, ChatBoxComponent, RulesComponent}

  def mount(%{"id" => game_id}, _session, socket) do
    maybe_subscribe(socket, game_id)

    case maybe_start_game(game_id, socket.assigns.me) do
      {:ok, _pid} -> :ok
      :already_started -> :ok
    end

    {:ok, initialize_socket(socket, game_id, socket.assigns.me)}
  end

  def terminate(_, socket) do
    Logger.info(
      "Terminating GameLive for game #{socket.assigns.game_id} and player #{socket.assigns.me.id}"
    )

    if Map.has_key?(socket.assigns, :game_id) do
      Game.remove_player(socket.assigns.game_id, socket.assigns.me.id)
    end

    :ok
  end

  def handle_info({:new_message, msg}, socket) do
    {:noreply, stream_insert(socket, :messages, msg)}
  end

  def handle_info(%{"event" => "game_started", "artist" => artist}, socket) do
    socket =
      socket
      |> assign(:game_started, true)
      |> assign(:current_artist, artist)
      |> stream_insert(
        :messages,
        system_msg("The game has started! Get ready to draw and guess!")
      )

    {:noreply, socket}
  end

  def handle_info(
        %{
          "event" => "round_started",
          "artist" => artist,
          "current_round" => current_round,
          "max_rounds" => max_rounds
        },
        socket
      ) do
    message =
      system_msg("Starting round #{current_round} of #{max_rounds}. The artist is now #{artist}.")

    {:noreply,
     socket
     |> assign(:game_started, true)
     |> assign(:current_artist, artist)
     |> stream_insert(:messages, message)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:ok, players} = Game.get_players(socket.assigns.game_id)
    {:noreply, assign(socket, players: Map.values(players))}
  end

  def handle_event("start", _params, socket) do
    Game.start(socket.assigns.game_id)
    {:noreply, socket}
  end

  def handle_event("send_message", %{"body" => body}, socket) do
    trimmed = String.trim(body)

    if trimmed != "" do
      msg = %{
        id: System.unique_integer([:positive]),
        body: trimmed,
        name: socket.assigns.me.name
      }

      Phoenix.PubSub.broadcast(
        Egaite.PubSub,
        "chat:#{socket.assigns.game_id}",
        {:new_message, msg}
      )

      reply_socket =
        case Game.guess(socket.assigns.game_id, socket.assigns.me.id, trimmed) do
          {:ok, :hit} ->
            socket
            |> stream_insert(:messages, system_msg("#{msg.name} guessed the word!"))
            |> stream_insert(:messages, msg)

          _ ->
            stream_insert(socket, :messages, msg)
        end

      {:noreply, reply_socket}
    else
      {:noreply, socket}
    end
  end

  defp maybe_subscribe(socket, game_id) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Egaite.PubSub, "game:#{game_id}")
      Phoenix.PubSub.subscribe(Egaite.PubSub, "chat:#{game_id}")
      Phoenix.PubSub.subscribe(Egaite.PubSub, "game_presence:#{game_id}")
    end
  end

  defp maybe_start_game(game_id, player) do
    try do
      Game.add_player(game_id, %Player{id: player.id, name: player.name})
      :already_started
    catch
      :exit, {:noproc, _} ->
        {:ok, pid} = GameSupervisor.start_game(game_id, %Player{id: player.id, name: player.name})
        {:ok, pid}
    end
  end

  defp initialize_socket(socket, game_id, player) do
    {:ok, players} = Game.get_players(game_id)
    current_artist = Game.get_current_artist(game_id)

    socket
    |> assign(:game_id, game_id)
    |> assign(:game_started, false)
    |> assign(:players, Map.values(players))
    |> assign(:current_artist, current_artist)
    |> assign(:full_screen, true)
    |> stream(:messages, [])
  end

  defp system_msg(body) do
    %{id: System.unique_integer([:positive]), body: body, name: "System"}
  end

  defp waiting_room(assigns) do
    ~H"""
    <div class="relative flex flex-col h-full justify-between">
      <%= if @current_artist == @me.id do %>
        <div
          class="absolute inset-0 flex flex-col items-center justify-center bg-black bg-opacity-70 text-white z-10 p-6"
          style="pointer-events:auto;"
        >
          <div class="max-w-lg w-full mb-6"><.rules /></div>
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
          <div class="max-w-lg w-full mb-4"><.rules /></div>
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

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
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
        <div class="h-1/2 overflow-auto border-b border-gray-300">
          <.players_list players={@players} artist={@current_artist} />
        </div>
        <div class="h-1/2 overflow-auto">
          <.chat_box messages={@streams.messages} />
        </div>
      </aside>
    </div>
    """
  end
end
