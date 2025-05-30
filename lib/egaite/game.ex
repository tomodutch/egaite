defmodule Egaite.Game do
  require Logger
  alias Egaite.{Game, Rules, Round, GameOptions, FuzzyMatcher}
  use GenServer

  defstruct id: :none,
            players: %{},
            player_order: [],
            points: Map.new(),
            current_artist: :none,
            word: :none,
            rules_pid: :none,
            bot_supervisor_pid: :none,
            round_duration: :none,
            break_duration: :none

  ## Public API

  def start_link({game_id, host_player, %GameOptions{} = opts}),
    do: start_link(game_id, host_player, opts)

  def start_link(game_id, host_player, %GameOptions{} = opts) do
    GenServer.start_link(__MODULE__, {game_id, host_player, opts}, name: via_tuple(game_id))
  end

  def child_spec({game_id, _host_player, opts} = args) do
    %{
      id: {:game, game_id, opts},
      start: {__MODULE__, :start_link, [args]},
      restart: :transient,
      type: :worker
    }
  end

  def ready_to_start?(game_id) do
    GenServer.call(via_tuple(game_id), :ready_to_start?)
  end

  def add_player(game_id, player), do: GenServer.call(via_tuple(game_id), {:add_player, player})

  def remove_player(game_id, player_id),
    do: GenServer.call(via_tuple(game_id), {:remove_player, player_id})

  def get_players(game_id), do: GenServer.call(via_tuple(game_id), :get_players)
  def get_current_artist(game_id), do: GenServer.call(via_tuple(game_id), :get_current_artist)
  def get_current_word(game_id), do: GenServer.call(via_tuple(game_id), :get_current_word)
  def get_points(game_id), do: GenServer.call(via_tuple(game_id), :get_points)

  def start(game_id), do: GenServer.call(via_tuple(game_id), :start)

  def guess(game_id, player_id, guess),
    do: GenServer.call(via_tuple(game_id), {:guess, player_id, guess})

  ## GenServer Callbacks

  def init({game_id, host_player, %GameOptions{} = opts}) do
    {:ok, bot_supervisor_pid} = DynamicSupervisor.start_link(strategy: :one_for_one)

    if opts.bot_count > 0 do
      for _ <- 1..opts.bot_count do
        bot_player = %Egaite.Player{
          id: Ecto.UUID.generate(),
          name: "🤖 " <> Egaite.NameGenerator.generate_name()
        }

        DynamicSupervisor.start_child(
          bot_supervisor_pid,
          {Egaite.GameBot, {game_id, bot_player, [speed: :slow, difficulty: :easy]}}
        )
      end
    end

    {:ok, rules_pid} = Rules.start_link(1, self(), opts.max_rounds)

    state = %Game{
      id: game_id,
      players: %{host_player.id => host_player},
      player_order: [host_player.id],
      current_artist: host_player.id,
      word: :none,
      rules_pid: rules_pid,
      bot_supervisor_pid: bot_supervisor_pid,
      points: %{host_player.id => 0},
      round_duration: opts.round_duration,
      break_duration: opts.break_duration
    }

    {:ok, state}
  end

  def handle_call(:ready_to_start?, _from, state) do
    resp =
      case Rules.ready_to_start?(state.rules_pid) do
        {:ok, true} -> true
        _ -> false
      end

    {:reply, resp, state}
  end

  def handle_info(:start, state) do
    case do_start(state) do
      {:ok, new_state} ->
        {:noreply, new_state}

      {:retry, new_state} ->
        Process.send_after(self(), :start, 5_000)
        {:noreply, new_state}

      {:error, reason, new_state} ->
        Logger.warning("Failed to start: #{inspect(reason)}")
        {:noreply, new_state}
    end
  end

  def handle_call(:start, _from, state) do
    case do_start(state) do
      {:ok, new_state} -> {:reply, {:ok, new_state.word}, new_state}
      {:retry, new_state} -> {:reply, {:error, :not_enough_players}, new_state}
      {:error, reason, new_state} -> {:reply, {:error, reason}, new_state}
    end
  end

  defp do_start(state) do
    case Rules.ready_to_start?(state.rules_pid) do
      {:ok, true} ->
        word = generate_word()
        new_state = %{state | word: word}
        artist_name = Map.get(state.players, state.current_artist).name
        {:ok, round_number, max_rounds} = Rules.start_round(state.rules_pid)

        Logger.info("Starting round with artist: #{artist_name}. Clearing canvas.")

        EgaiteWeb.Endpoint.broadcast("drawing:#{state.id}", "clear_canvas", %{
          "artist" => state.current_artist,
          "artist_name" => artist_name
        })

        Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
          "event" => "round_started",
          "artist" => state.current_artist,
          "current_round" => round_number,
          "max_rounds" => max_rounds,
          "artist_name" => artist_name,
          "word_to_draw" => word,
          "player_points" => new_state.points
        })

        Process.send_after(self(), {:end_round, round_number}, state.round_duration)

        {:ok, new_state}

      {:ok, false} ->
        {:retry, state}

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  @impl true
  def handle_info({:end_round, round_number}, state) do
    Rules.end_round(state.rules_pid, round_number)
    {:noreply, state}
  end

  def handle_call({:guess, _player_id, _guess}, _from, %Game{word: :none} = state) do
    {:reply, {:error, :word_not_set}, state}
  end

  def handle_call({:guess, player_id, _guess}, _from, %Game{current_artist: player_id} = state) do
    {:reply, {:error, :artist_can_not_guess}, state}
  end

  def handle_call({:guess, player_id, guess}, _from, state) do
    Logger.info("Player #{player_id} guessed: #{guess}")

    if FuzzyMatcher.word_in_sentence?(state.word, guess) do
      Logger.info("Player guessed correctly: #{guess}")

      case Rules.guessed_correctly(state.rules_pid, player_id) do
        {:error, :player_already_guessed} ->
          {:reply, {:error, :already_guessed}, state}

        {:error, reason} ->
          {:reply, {:error, reason}, state}

        {:ok, true} ->
          Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
            "event" => "player_guessed_correctly",
            "player_id" => player_id,
            "player_name" => Map.get(state.players, player_id).name
          })

          updated_points =
            state.points
            |> Map.update(player_id, 1, &(&1 + 1))
            |> Map.update(state.current_artist, 1, &(&1 + 1))

          {:reply, {:ok, :hit}, %{state | points: updated_points}}
      end
    else
      {:reply, {:ok, :miss}, state}
    end
  end

  def handle_call({:add_player, player}, _from, state) do
    if Map.has_key?(state.players, player.id) do
      {:reply, {:error, {:already_joined, player.id}}, state}
    else
      new_players = Map.put(state.players, player.id, player)
      new_order = state.player_order ++ [player.id]
      new_points = Map.put(state.points, player.id, 0)
      Rules.set_player_count(state.rules_pid, map_size(new_players))

      Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
        "event" => "player_joined",
        "player" => player,
        "players" => new_players
      })

      {:reply, :ok, %{state | players: new_players, player_order: new_order, points: new_points}}
    end
  end

  def handle_call({:remove_player, player_id}, _from, state) do
    Logger.info("Removing player #{player_id} from game #{state.id}")
    player = Map.get(state.players, player_id)

    if !is_nil(player) do
      new_players = Map.delete(state.players, player_id)
      new_order = List.delete(state.player_order, player_id)
      Rules.set_player_count(state.rules_pid, map_size(new_players))

      Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
        "event" => "player_left",
        "player" => player,
        "players" => new_players
      })

      {:reply, :ok, %{state | players: new_players, player_order: new_order}}
    else
      Logger.info("Tried removing player #{player_id} but not found in game #{state.id}")
      {:reply, :ok, state}
    end
  end

  def handle_call(:get_players, _from, state) do
    {:reply, {:ok, state.players}, state}
  end

  def handle_call(:get_current_artist, _from, state) do
    current_artist =
      case state.current_artist do
        :none -> List.first(state.player_order)
        _ -> state.current_artist
      end

    {:reply, current_artist, state}
  end

  def handle_call(:get_current_word, _from, state) do
    {:reply, {:ok, state.word}, state}
  end

  def handle_call(:get_points, _from, state) do
    {:reply, {:ok, state.points}, state}
  end

  def handle_info(:game_over, state) do
    Logger.info("Game finished.")

    Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
      "event" => "game_ended",
      "points" => state.points
    })

    {:stop, :normal, state}
  end

  def handle_info({:round_ended, {round_num, max_rounds}}, state) do
    Logger.info("Round #{round_num}/#{max_rounds} ended.")
    next_artist = get_next_artist(state.current_artist, state.player_order)
    Process.send_after(self(), :start, state.break_duration)

    Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
      "event" => "round_ended",
      "current_round" => round_num,
      "max_rounds" => max_rounds,
      "next_artist" => next_artist,
      "player_points" => state.points
    })

    new_state = %{
      state
      | current_artist: next_artist
    }

    {:noreply, new_state}
  end

  ## Private

  defp via_tuple(game_id), do: {:via, Registry, {Egaite.GameRegistry, game_id}}

  defp generate_word do
    # Placeholder. Get from database
    Enum.random([
      "cat",
      "dog",
      "elephant",
      "giraffe",
      "monkey",
      "rabbit",
      "dolphin",
      "turtle",
      "lion",
      "panda",
      "snake"
    ])
  end

  defp get_next_artist(current, players) do
    case Enum.find_index(players, &(&1 == current)) do
      nil -> List.first(players)
      index -> Enum.at(players, rem(index + 1, length(players)))
    end
  end
end
