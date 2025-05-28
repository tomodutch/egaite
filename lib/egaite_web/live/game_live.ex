defmodule EgaiteWeb.GameLive do
  use EgaiteWeb, :live_view
  require Logger
  alias Egaite.{GameSupervisor, Game, Player}
  import EgaiteWeb.{CanvasComponent, PlayersListComponent, ChatBoxComponent, RulesComponent}

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    maybe_subscribe(socket, game_id)

    case maybe_start_game(game_id, socket.assigns.me) do
      {:ok, _pid} -> :ok
      :already_started -> :ok
    end

    {:ok,
     initialize_socket(socket, game_id, socket.assigns.me)
     |> assign(:active_tab, "chat")}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("start", _params, socket) do
    Game.start(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
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

  @impl true
  def handle_info({:new_message, msg}, socket) do
    {:noreply, stream_insert(socket, :messages, msg)}
  end

  @impl true
  def handle_info(%{"event" => "player_joined", "player" => player, "players" => players}, socket) do
    socket =
      socket
      |> assign(:players, Map.values(players))
      |> stream_insert(:messages, system_msg("#{player.name} has joined the game!"))

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{"event" => "player_left", "player" => player, "players" => players}, socket) do
    socket =
      socket
      |> assign(:players, Map.values(players))
      |> stream_insert(:messages, system_msg("#{player.name} has left the game!"))

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{"event" => "game_ended"}, socket) do
    socket =
      socket
      |> assign(:game_started, false)
      |> assign(:current_artist, nil)
      |> stream_insert(:messages, system_msg("The game has ended. Thanks for playing!"))

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{"event" => "game_started", "artist" => artist, "word_to_draw" => word_to_draw},
        socket
      ) do
    socket =
      socket
      |> assign(:game_started, true)
      |> assign(:current_artist, artist)
      |> assign(:word, word_to_draw)
      |> stream_insert(
        :messages,
        system_msg("The game has started! Get ready to draw and guess!")
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{
          "event" => "round_started",
          "artist" => artist,
          "artist_name" => artist_name,
          "current_round" => current_round,
          "max_rounds" => max_rounds,
          "word_to_draw" => word_to_draw
        },
        socket
      ) do
    message =
      system_msg(
        "Starting round #{current_round} of #{max_rounds}. The artist is now #{artist_name}."
      )

    {:noreply,
     socket
     |> assign(:game_started, true)
     |> assign(:current_artist, artist)
     |> assign(:word, word_to_draw)
     |> stream_insert(:messages, message)}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:ok, players} = Game.get_players(socket.assigns.game_id)
    {:noreply, assign(socket, players: Map.values(players))}
  end

  # Helper Functions

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
    |> assign(:word, nil)
    |> stream(:messages, [])
  end

  defp system_msg(body) do
    %{id: System.unique_integer([:positive]), body: body, name: "System"}
  end

  defp tab_class(active, current) do
    base = "w-full text-center py-2 border-b-2"

    if active == current do
      base <> " border-blue-600 text-blue-600 font-semibold"
    else
      base <> " border-transparent text-gray-500 hover:text-gray-700"
    end
  end

  defp waiting_room(assigns) do
    ~H"""
    <div class="h-full pt-12 flex flex-col justify-center items-center overflow-auto px-4 text-center">
      <%= if @current_artist == @me.id do %>
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

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="game-container"
      phx-hook="GamePresence"
      data-gameId={@game_id}
      data-playerId={@me.id}
      class="flex flex-col md:flex-row h-screen bg-white"
    >
      <!-- Left: Canvas section -->
      <div class="md:w-2/3 w-full md:h-full flex flex-col border-r h-1/2">
        <div class="bg-blue-100 border border-blue-500 text-blue-800 font-bold p-2 text-center flex-shrink-0 h-12 sticky top-0 z-10">
          <%= cond do %>
            <% !@game_started -> %>
              Waiting for the artist to start the game...
            <% @current_artist == @me.id -> %>
              🎨 Draw: {@word}
            <% true -> %>
            Guess in chat!
          <% end %>
        </div>

    <!-- Canvas or waiting room fills the rest -->
        <div class="flex-grow overflow-hidden">
          <%= if @game_started do %>
            <.canvas
              canvas_id="game-canvas"
              game_id={@game_id}
              player_id={@me.id}
              player_name={@me.name}
              artist={@current_artist}
              class="w-full h-full"
            />
          <% else %>
            {waiting_room(assigns)}
          <% end %>
        </div>
      </div>

    <!-- Right: Tabs section -->
      <div class="md:w-1/3 w-full md:h-full flex flex-col h-1/2">
        <!-- Tabs navigation -->
        <nav class="flex border-b text-sm md:text-base h-12">
          <!-- fixed height 3rem (12) -->
          <button phx-click="set_tab" phx-value-tab="chat" class={tab_class(@active_tab, "chat")}>
            Chat
          </button>
          <button
            phx-click="set_tab"
            phx-value-tab="players"
            class={tab_class(@active_tab, "players")}
          >
            Players
          </button>
          <button phx-click="set_tab" phx-value-tab="rules" class={tab_class(@active_tab, "rules")}>
            Rules
          </button>
        </nav>

    <!-- Tab content -->
        <div class="flex-1 overflow-auto relative">
          <div class={"h-full tab-panel " <> if(@active_tab == "chat", do: "block", else: "hidden")}>
            <.chat_box messages={@streams.messages} />
          </div>
          <div class={"h-full tab-panel " <> if(@active_tab == "players", do: "block", else: "hidden")}>
            <.players_list players={@players} artist={@current_artist} />
          </div>
          <div class={"h-full tab-panel " <> if(@active_tab == "rules", do: "block", else: "hidden")}>
            <.rules />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
