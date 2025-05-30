defmodule Egaite.Rules do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]
  require Logger

  alias __MODULE__

  defstruct player_count: 0,
            game_pid: :none,
            round: 1,
            max_rounds: 8,
            guessed_correctly: MapSet.new()

  # Public API

  def start_link(player_count, game_pid, max_rounds \\ 8) do
    GenStateMachine.start_link(__MODULE__, {player_count, game_pid, max_rounds})
  end

  def ready_to_start?(pid), do: GenStateMachine.call(pid, :ready_to_start?)
  def start_round(pid), do: GenStateMachine.call(pid, :start_round)
  def end_round(pid, round_number), do: GenStateMachine.cast(pid, {:end_round, round_number})
  def set_player_count(pid, count), do: GenStateMachine.cast(pid, {:set_player_count, count})

  def guessed_correctly(pid, player_id),
    do: GenStateMachine.call(pid, {:guessed_correctly, player_id})

  # Initialization

  def init({player_count, game_pid, max_rounds}) do
    state = if player_count >= 2, do: :ready_to_start, else: :waiting_for_players

    {:ok, state,
     %Rules{
       player_count: player_count,
       game_pid: game_pid,
       round: 1,
       max_rounds: max_rounds,
       guessed_correctly: MapSet.new()
     }}
  end

  # === State: waiting_for_players ===

  def waiting_for_players(:enter, _event, _state), do: {:keep_state_and_data, []}

  def waiting_for_players({:call, from}, :ready_to_start?, %Rules{player_count: count})
      when count >= 2 do
    {:keep_state_and_data, [{:reply, from, {:ok, true}}]}
  end

  def waiting_for_players({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:ok, false}}]}
  end

  def waiting_for_players({:call, from}, :start_round, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :round_not_active}}]}
  end

  def waiting_for_players(:cast, {:set_player_count, 0}, data) do
    {:next_state, :game_over, %{data | player_count: 0}}
  end

  def waiting_for_players(:cast, {:end_round, _round_number}, _data) do
    {:keep_state_and_data, []}
  end

  def waiting_for_players(:cast, {:set_player_count, count}, data) when count >= 2 do
    {:next_state, :ready_to_start, %{data | player_count: count}}
  end

  def waiting_for_players(:cast, {:set_player_count, count}, data) do
    {:keep_state, %{data | player_count: count}}
  end

  def waiting_for_players({:call, from}, {:guessed_correctly, _player_id}, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :round_not_active}}]}
  end

  # === State: ready_to_start ===

  def ready_to_start(:enter, _event, _state), do: {:keep_state_and_data, []}

  def ready_to_start(:cast, {:end_round, _round_number}, _data) do
    {:keep_state_and_data, []}
  end

  def ready_to_start({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:ok, true}}]}
  end

  def ready_to_start({:call, from}, :start_round, data) do
    {:next_state, :round_active,
     %Rules{data | round: data.round, guessed_correctly: MapSet.new()},
     [{:reply, from, {:ok, data.round, data.max_rounds}}]}
  end

  def ready_to_start(:cast, {:set_player_count, 1}, data) do
    {:next_state, :waiting_for_players, %{data | player_count: 1}}
  end

  def ready_to_start(:cast, {:set_player_count, 0}, data) do
    {:next_state, :game_over, %{data | player_count: 0}}
  end

  def ready_to_start(:cast, {:set_player_count, count}, data) do
    {:keep_state, %{data | player_count: count}}
  end

  def ready_to_start({:call, from}, {:guessed_correctly, _player_id}, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :round_not_active}}]}
  end

  # === State: round_active ===

  def round_active(:cast, {:end_round, round_number}, %{round: round_number} = data) do
    {:next_state, :round_ended, data}
  end

  def round_active(:cast, {:end_round, _round_number}, _data) do
    {:keep_state_and_data, []}
  end

  def round_active(:enter, _event, _state), do: {:keep_state_and_data, []}

  def round_active({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :game_in_progress}}]}
  end

  def round_active(:cast, {:set_player_count, count}, data) when count < 2 do
    {:next_state, :game_over, %{data | player_count: 0}}
  end

  def round_active(:cast, {:set_player_count, count}, data) do
    {:keep_state, %{data | player_count: count}}
  end

  def round_active({:call, from}, {:guessed_correctly, player_id}, data) do
    if MapSet.member?(data.guessed_correctly, player_id) do
      {:keep_state_and_data, [{:reply, from, {:error, :player_already_guessed}}]}
    else
      updated_set = MapSet.put(data.guessed_correctly, player_id)
      new_data = %Rules{data | guessed_correctly: updated_set}

      reply = {:reply, from, {:ok, true}}

      if MapSet.size(updated_set) >= new_data.player_count - 1 do
        {:next_state, :round_ended, new_data, [reply]}
      else
        {:keep_state, new_data, [reply]}
      end
    end
  end

  # === State: round_ended ===

  def round_ended(:enter, _event, data) do
    Logger.info("Round ended, waiting for next round to start")
    send(data.game_pid, {:round_ended, {data.round, data.max_rounds}})
    {:keep_state_and_data, []}
  end

  def round_ended(:cast, {:end_round, _round_number}, _data) do
    {:keep_state_and_data, []}
  end

  def round_ended({:call, from}, {:guessed_correctly, _player_id}, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :round_ended}}]}
  end

  def round_ended({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:ok, true}}]}
  end

  def round_ended({:call, from}, :start_round, data) do
    Logger.info("Starting next round")
    new_data = %Rules{data | round: data.round + 1, guessed_correctly: MapSet.new()}

    if new_data.round <= new_data.max_rounds do
      {:next_state, :round_active, new_data, [{:reply, from, {:ok, new_data.round, new_data.max_rounds}}]}
    else
      {:next_state, :game_over, new_data, [{:reply, from, {:ok, new_data.round, new_data.max_rounds}}]}
    end
  end

  def round_ended(:cast, {:set_player_count, count}, data) do
    {:keep_state, %{data | player_count: count}}
  end

  # === State: game_over ===

  def game_over(:enter, _event, data) do
    send(data.game_pid, :game_over)
    {:keep_state_and_data, []}
  end

  def game_over(:cast, {:end_round, _round_number}, _data) do
    {:keep_state_and_data, []}
  end

  def game_over({:call, from}, :ready_to_start?, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :game_finished}}]}
  end

  def game_over({:call, from}, :start_round, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :game_finished}}]}
  end

  def game_over(:cast, {:set_player_count, count}, data) do
    {:keep_state, %{data | player_count: count}}
  end

  def game_over({:call, from}, {:guessed_correctly, _player_id}, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :game_finished}}]}
  end
end
