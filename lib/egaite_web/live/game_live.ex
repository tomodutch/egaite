defmodule EgaiteWeb.GameLive do
  use EgaiteWeb, :live_view
  require Logger
  alias Egaite.{Player, Game, GameSupervisor}

  import EgaiteWeb.{
    CanvasComponent,
    WaitingRoomComponent,
    StatusBannerComponent,
    GameOverComponent,
    TabsComponent
  }

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

  def system_msg(body) do
    %{id: System.unique_integer([:positive]), body: body, name: "System"}
  end

  def maybe_start_game(game_id, player) do
    try do
      Game.add_player(game_id, %Player{id: player.id, name: player.name})
      :already_started
    catch
      :exit, {:noproc, _} ->
        {:ok, pid} = GameSupervisor.start_game(game_id, %Player{id: player.id, name: player.name})
        {:ok, pid}
    end
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
  def handle_info(%{"event" => "game_ended", "points" => points}, socket) do
    Logger.info("Game ended for #{socket.assigns.game_id}")
    socket =
      socket
      |> assign(:game_started, false)
      |> assign(:game_over, true)
      |> assign(:current_artist, nil)
      |> assign(:player_points, points)
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
          "word_to_draw" => word_to_draw,
          "player_points" => player_points
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
      |> assign(:player_points, player_points)
     |> stream_insert(:messages, message)}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:ok, players} = Game.get_players(socket.assigns.game_id)
    {:noreply, assign(socket, players: Map.values(players))}
  end

  defp maybe_subscribe(socket, game_id) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Egaite.PubSub, "game:#{game_id}")
      Phoenix.PubSub.subscribe(Egaite.PubSub, "chat:#{game_id}")
      Phoenix.PubSub.subscribe(Egaite.PubSub, "game_presence:#{game_id}")
    end
  end

  defp initialize_socket(socket, game_id, _player) do
    {:ok, players} = Game.get_players(game_id)
    {:ok, player_points} = Game.get_points(game_id)
    current_artist = Game.get_current_artist(game_id)

    socket
    |> assign(:game_id, game_id)
    |> assign(:game_started, false)
    |> assign(:game_over, false)
    |> assign(:players, Map.values(players))
    |> assign(:current_artist, current_artist)
    |> assign(:full_screen, true)
    |> assign(:word, nil)
    |> assign(:player_points, player_points)
    |> stream(:messages, [])
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
      <div class="md:w-2/3 w-full md:h-full flex flex-col border-r h-1/2">
        <.game_status_banner
          game_started={@game_started}
          is_artist={@current_artist == @me.id}
          word={@word}
        />

        <div class="flex-grow overflow-hidden">
          <%= case {@game_started, @game_over} do %>
            <% {true, _} -> %>
              <.canvas
                canvas_id="game-canvas"
                game_id={@game_id}
                player_id={@me.id}
                player_name={@me.name}
                artist={@current_artist}
              />
            <% {_, true} -> %>
              <.game_over players={@players} points={@player_points} />
            <% _ -> %>
              <.waiting_room is_artist={@current_artist == @me.id} />
          <% end %>
        </div>
      </div>

      <.tabs_component
        active_tab={@active_tab}
        players={@players}
        player_points={@player_points}
        current_artist={@current_artist}
        messages={@streams.messages}
      />
    </div>
    """
  end
end
