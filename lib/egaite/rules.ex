defmodule Egaite.Rules do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]
  require Logger

  alias __MODULE__

  defstruct player_count: 0, game_pid: :none, round: 1, max_rounds: 8, guessed_correctly: 0

  # Public API

  def start_link(player_count, game_pid, max_rounds \\ 8) do
    GenStateMachine.start_link(__MODULE__, {player_count, game_pid, max_rounds})
  end

  def ready_to_start?(pid), do: GenStateMachine.call(pid, :ready_to_start?)
  def start_round(pid), do: GenStateMachine.cast(pid, :start_round)
  def set_player_count(pid, count), do: GenStateMachine.cast(pid, {:set_player_count, count})
  def guessed_correctly(pid), do: GenStateMachine.cast(pid, :guessed_correctly)

  # Initialization

  def init({player_count, game_pid, max_rounds}) do
    {:ok, :waiting_for_players,
     %Rules{
       player_count: player_count,
       game_pid: game_pid,
       round: 1,
       max_rounds: max_rounds,
       guessed_correctly: 0
     }}
  end

  # State: waiting_for_players

  def waiting_for_players(:enter, _event, _state), do: {:keep_state_and_data, []}

  def waiting_for_players({:call, from}, :ready_to_start?, %Rules{player_count: count})
      when count >= 2 do
    {:keep_state_and_data, [{:reply, from, {:ok, true}}]}
  end

  def waiting_for_players({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:ok, false}}]}
  end

  def waiting_for_players(:cast, :start_round, data), do: {:keep_state, data}

  def waiting_for_players(:cast, {:set_player_count, 0}, data),
    do: {:next_state, :game_over, %{data | player_count: 0}}

  def waiting_for_players(:cast, {:set_player_count, count}, data) when count >= 2 do
    {:next_state, :ready_to_start, %{data | player_count: count}}
  end

  def waiting_for_players(:cast, {:set_player_count, count}, data),
    do: {:keep_state, %{data | player_count: count}}

  def waiting_for_players(:cast, :guessed_correctly, _data), do: {:keep_state_and_data}
  # State: ready_to_start

  def ready_to_start(:enter, _event, _state), do: {:keep_state_and_data, []}

  def ready_to_start({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:ok, true}}]}
  end

  def ready_to_start(:cast, :start_round, data) do
    Logger.info("Starting the game")
    new_data = %Rules{data | round: data.round + 1}
    {:next_state, :round_active, new_data, {:state_timeout, 60_000, :round_timeout}}
  end

  def ready_to_start(:cast, {:set_player_count, 1}, data),
    do: {:next_state, :waiting_for_players, %{data | player_count: 1}}

  def ready_to_start(:cast, {:set_player_count, 0}, data),
    do: {:next_state, :game_over, %{data | player_count: 0}}

  def ready_to_start(:cast, {:set_player_count, count}, data),
    do: {:keep_state, %{data | player_count: count}}

  def ready_to_start(:cast, :guessed_correctly, _data), do: {:keep_state_and_data}
  # State: round_active

  def round_active(:enter, _event, _state), do: {:keep_state_and_data, []}

  def round_active({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :game_in_progress}}]}
  end

  def round_active(:state_timeout, :round_timeout, data) do
    Logger.info("Round timeout reached")
    # Notify game that round ended
    send(data.game_pid, {:round_ended, {data.round, data.max_rounds}})

    if data.round <= data.max_rounds do
      {:next_state, :ready_to_start, %Rules{data | guessed_correctly: 0}}
    else
      {:next_state, :game_over, data}
    end
  end

  def round_active(:cast, {:set_player_count, count}, data) when count < 2 do
    {:next_state, :game_over, %{data | player_count: 0}}
  end

  def round_active(:cast, {:set_player_count, count}, data),
    do: {:keep_state, %{data | player_count: count}}

  def round_active(:cast, :guessed_correctly, data) do
    guessed_correctly = data.guessed_correctly + 1
    new_data = %Rules{data | guessed_correctly: guessed_correctly}
    Logger.info("Logged correctly: #{guessed_correctly}/#{data.player_count - 1}")

    if guessed_correctly >= data.player_count - 1 do
      send(data.game_pid, {:round_ended, {data.round, data.max_rounds}})

      if data.round <= data.max_rounds do
        {:next_state, :ready_to_start, %Rules{new_data | guessed_correctly: 0}}
      else
        {:next_state, :game_over, data}
      end
    else
      {:keep_state, new_data}
    end
  end

  # State: game_over
  def game_over(:enter, _event, _state) do
    {:keep_state_and_data, [{:timeout, 0, :send_game_over}]}
  end

  def game_over(:timeout, :send_game_over, state) do
    send(state.game_pid, :game_over)
    {:keep_state_and_data, []}
  end

  def game_over({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :game_finished}}]}
  end

  def game_over(:cast, :start_round, _data), do: {:keep_state_and_data, []}

  def game_over(:cast, {:set_player_count, count}, data),
    do: {:keep_state, %{data | player_count: count}}
end
