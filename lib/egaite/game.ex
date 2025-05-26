defmodule Egaite.Game do
  require Logger
  alias ElixirSense.Log
  alias Egaite.{Game, Rules}
  use GenServer

  defstruct id: :none,
            players: %{},
            player_order: [],
            current_artist: :none,
            word: :none,
            rules_pid: :none

  ## Public API

  def start_link({game_id, host_player}), do: start_link(game_id, host_player)

  def start_link(game_id, host_player, max_rounds \\ 8) do
    GenServer.start_link(__MODULE__, {game_id, host_player, max_rounds}, name: via_tuple(game_id))
  end

  def child_spec({game_id, _host_player} = args) do
    %{
      id: {:game, game_id},
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
  def start(game_id), do: GenServer.call(via_tuple(game_id), :start)

  def guess(game_id, player_id, guess),
    do: GenServer.call(via_tuple(game_id), {:guess, player_id, guess})

  ## GenServer Callbacks

  def init({game_id, host_player, max_rounds}) do
    {:ok, rules_pid} = Rules.start_link(1, self(), max_rounds)

    state = %Game{
      id: game_id,
      players: %{host_player.id => host_player},
      player_order: [host_player.id],
      current_artist: host_player.id,
      word: :none,
      rules_pid: rules_pid
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

  def handle_call(:start, _from, state) do
    case Rules.ready_to_start?(state.rules_pid) do
      {:ok, true} ->
        word = generate_word()
        Rules.start_round(state.rules_pid)
        new_state = %{state | word: word}

        Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
          "event" => "game_started",
          "artist" => state.current_artist,
          "word_to_draw" => word
        })

        Phoenix.PubSub.broadcast(Egaite.PubSub, "drawing:#{state.id}", %{
          "event" => "clear_canvas",
          "artist" => state.current_artist
        })

        {:reply, {:ok, word}, new_state}

      {:ok, false} ->
        {:reply, {:error, :not_enough_players}, state}

      {:error, :game_in_progress} ->
        Logger.info("Game in progress.")
        {:noreply, state}

      {:error, :game_finished} ->
        Logger.info("Game finished.")
        {:stop, :normal, state}
    end
  end

  def handle_call({:guess, _player_id, _guess}, _from, %Game{word: :none} = state) do
    {:reply, {:error, :word_not_set}, state}
  end

  def handle_call({:guess, player_id, _guess}, _from, %Game{current_artist: player_id} = state) do
    {:reply, {:error, :artist_can_not_guess}, state}
  end

  def handle_call({:guess, _player_id, guess}, _from, state) do
    if String.downcase(guess) == String.downcase(state.word) do
      Rules.guessed_correctly(state.rules_pid)
      {:reply, {:ok, :hit}, state}
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
      Rules.set_player_count(state.rules_pid, map_size(new_players))

      Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
        "event" => "player_joined",
        "player" => player,
        "players" => new_players
      })

      {:reply, :ok, %{state | players: new_players, player_order: new_order}}
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

  def handle_info(:game_over, state) do
    Logger.info("Game finished.")

    Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
      "event" => "game_ended"
    })

    {:stop, :normal, state}
  end

  def handle_info({:round_ended, {round_num, max_rounds}}, state) do
    Logger.info("Round #{round_num}/#{max_rounds} ended.")

    case Rules.ready_to_start?(state.rules_pid) do
      {:ok, true} ->
        word = generate_word()
        Rules.start_round(state.rules_pid)
        next_artist = get_next_artist(state.current_artist, state.player_order)
        new_state = %{state | word: word, current_artist: next_artist}

        artist_name = Map.get(state.players, next_artist).name

        Phoenix.PubSub.broadcast(Egaite.PubSub, "drawing:#{state.id}", %{
          "event" => "clear_canvas",
          "artist" => next_artist,
          "artist_name" => artist_name
        })

        Phoenix.PubSub.broadcast(Egaite.PubSub, "game:#{state.id}", %{
          "event" => "round_started",
          "artist" => next_artist,
          "current_round" => round_num,
          "max_rounds" => max_rounds,
          "artist_name" => artist_name,
          "word_to_draw" => word
        })

        {:noreply, new_state}

      {:ok, false} ->
        Logger.info("Not enough players. Waiting...")
        {:noreply, state}

      {:error, :game_in_progress} ->
        Logger.info("Game in progress.")
        {:noreply, state}

      {:error, :game_finished} ->
        Logger.info("Game finished.")
        {:stop, :normal, state}
    end
  end

  ## Private

  defp via_tuple(game_id), do: {:via, Registry, {Egaite.GameRegistry, game_id}}

  defp generate_word do
    # Placeholder
    "cat"
  end

  defp get_next_artist(current, players) do
    case Enum.find_index(players, &(&1 == current)) do
      nil -> List.first(players)
      index -> Enum.at(players, rem(index + 1, length(players)))
    end
  end
end
