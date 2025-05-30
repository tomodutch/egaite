defmodule Egaite.GameBot do
  use GenServer
  alias Egaite.{GameBot, Player, Game}

  defstruct game_id: :none,
            player: %Player{},
            # :slow | :medium | :fast
            speed: :medium,
            # :easy | :normal | :hard
            difficulty: :normal,
            current_word: nil,
            guessing: false,
            guess_timer_ref: nil

  # --- Public API

  def start_link(game_id, player, opts \\ []) do
    speed = Keyword.get(opts, :speed, :medium)
    difficulty = Keyword.get(opts, :difficulty, :normal)
    GenServer.start_link(__MODULE__, {game_id, player, speed, difficulty})
  end

  def child_spec({game_id, player, opts}) do
    %{
      id: {__MODULE__, player.id},
      start: {__MODULE__, :start_link, [game_id, player, opts]},
      restart: :transient,
      type: :worker
    }
  end

  # --- GenServer callbacks

  @impl true
  def init({game_id, player, speed, difficulty}) do
    send(self(), :after_init)

    {:ok,
     %GameBot{
       game_id: game_id,
       player: player,
       speed: speed,
       difficulty: difficulty,
       guess_timer_ref: nil,
       current_word: nil,
       guessing: false
     }}
  end

  @impl true
  def handle_info(
        %{
          "event" => "player_guessed_correctly",
          "player_id" => _,
          "player_name" => _
        },
        state
      ) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:after_init, state) do
    :ok = Game.add_player(state.game_id, state.player)

    Phoenix.PubSub.subscribe(Egaite.PubSub, "game:#{state.game_id}")
    Phoenix.PubSub.subscribe(Egaite.PubSub, "chat:#{state.game_id}")
    Phoenix.PubSub.subscribe(Egaite.PubSub, "game_presence:#{state.game_id}")
    Phoenix.PubSub.subscribe(Egaite.PubSub, "drawing:#{state.game_id}")

    # Send hello message after a random delay
    Process.send_after(self(), :say_hello, :rand.uniform(3_000) + 1_000)

    {:noreply, state}
  end

  def handle_info({"draw_batch", _points}, state) do
    # Handle drawing updates if needed
    {:noreply, state}
  end

  def handle_info(:say_hello, state) do
    greetings = [
      "Hello everyone!",
      "🤖 Ready to draw!",
      "Let's do this!",
      "Hi friends!",
      "Bot here to play!"
    ]

    send_message(state, Enum.random(greetings))
    {:noreply, state}
  end

  # Handle start of round: start guessing
  def handle_info(
        %{
          "event" => "round_started",
          "artist" => artist,
          "word_to_draw" => word_to_draw
        },
        state
      ) do
    if state.guess_timer_ref do
      Process.cancel_timer(state.guess_timer_ref)
    end

    if state.player.id == artist do
      send_message(state, "I'm the artist this round! Drawing: #{word_to_draw}")
      {:noreply, %{state | guessing: false, current_word: word_to_draw}}
    else
      ref = Process.send_after(self(), :make_guess, guess_interval(state.speed))

      {:noreply, %{state | current_word: word_to_draw, guessing: true, guess_timer_ref: ref}}
    end
  end

  def handle_info(
        %{
          "event" => "game_started",
          "artist" => artist,
          "word_to_draw" => word_to_draw
        },
        state
      ) do
    if state.guess_timer_ref do
      Process.cancel_timer(state.guess_timer_ref)
    end

    if state.player.id == artist do
      send_message(state, "I'm the artist this round! Drawing: #{word_to_draw}")
      {:noreply, %{state | guessing: false, current_word: word_to_draw}}
    else
      ref = Process.send_after(self(), :make_guess, guess_interval(state.speed))

      {:noreply, %{state | current_word: word_to_draw, guessing: true, guess_timer_ref: ref}}
    end
  end

  # Handle guess loop
  def handle_info(:make_guess, %{guessing: false} = state), do: {:noreply, state}

  def handle_info(:make_guess, state) do
    maybe_correct =
      case state.difficulty do
        :easy -> :rand.uniform(100) <= 30
        :normal -> :rand.uniform(100) <= 60
        :hard -> :rand.uniform(100) <= 85
      end

    guess =
      if maybe_correct do
        state.current_word
      else
        distractor_word(state.current_word)
      end

    send_message(state, format_guess(guess))

    ref =
      case Game.guess(state.game_id, state.player.id, guess) do
        {:ok, :hit} -> nil
        {:ok, :miss} -> Process.send_after(self(), :make_guess, guess_interval(state.speed))
      end

    {:noreply, %{state | guess_timer_ref: ref}}
  end

  # Handle game ended
  def handle_info(%{"event" => "game_ended"}, state) do
    if state.guess_timer_ref, do: Process.cancel_timer(state.guess_timer_ref)

    farewells = [
      "GG everyone!",
      "That was fun!",
      "🤖 Bot out. See ya!",
      "Thanks for the game!",
      "See you next round!"
    ]

    send_message(state, Enum.random(farewells))

    {:noreply, %{state | guessing: false, current_word: nil, guess_timer_ref: nil}}
  end

  # Optionally cancel on round end
  def handle_info(%{"event" => "round_ended"}, state) do
    if state.guess_timer_ref, do: Process.cancel_timer(state.guess_timer_ref)
    {:noreply, %{state | guessing: false, guess_timer_ref: nil}}
  end

  # Ignore these for now
  def handle_info({:new_message, _msg}, state), do: {:noreply, state}
  def handle_info(%{"event" => "player_joined"}, state), do: {:noreply, state}
  def handle_info(%{"event" => "player_left"}, state), do: {:noreply, state}
  def handle_info(%{"event" => "presence_diff"}, state), do: {:noreply, state}
  def handle_info(_, state), do: {:noreply, state}

  # --- Internal helpers

  defp guess_interval(:slow), do: 5_000
  defp guess_interval(:medium), do: 3_000
  defp guess_interval(:fast), do: 1_000

  defp send_message(state, message) do
    Phoenix.PubSub.broadcast(
      Egaite.PubSub,
      "chat:#{state.game_id}",
      {:new_message,
       %{
         id: System.unique_integer([:positive]),
         body: message,
         name: state.player.name
       }}
    )
  end

  defp distractor_word(actual_word) do
    fake_words = [
      "sun",
      "mountain",
      "tree",
      "car",
      "house",
      "pencil",
      "robot",
      "banana"
    ]

    Enum.random(fake_words -- [actual_word])
  end

  defp format_guess(word) do
    templates = [
      "Is it a #{word}?",
      "Maybe it's a #{word}?",
      "#{word}?",
      "Could it be a #{word}?",
      "I'm guessing a #{word}",
      "How about a #{word}?",
      "Looks like a #{word} to me",
      "That has to be a #{word}!",
      "I think it's a #{word}",
      "#{word} for sure"
    ]

    Enum.random(templates)
  end
end
