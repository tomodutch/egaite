defmodule EgaiteWeb.GameCreateLive do
  use EgaiteWeb, :live_view
  alias Egaite.{GameForm, GameSupervisor, Game, Player, GameOptions}

  def mount(_params, _session, socket) do
    changeset =
      GameForm.changeset(
        %GameForm{
          nickname: socket.assigns.me.name,
          game_name: "New Game",
          rounds: 4,
          bot_count: 0
        },
        %{}
      )

    form = to_form(changeset)

    socket =
      socket
      |> assign(full_screen: true)
      |> assign(changeset: changeset)
      |> assign(form: form)

    {:ok, socket}
  end

  def handle_event("create_game", %{"game_form" => game_params}, socket) do
    changeset = GameForm.changeset(%GameForm{}, game_params)

    if changeset.valid? do
      game_id = Ecto.UUID.generate()
      player = %Player{id: socket.assigns.me.id, name: game_params["nickname"]}

      {:ok, _} =
        GameSupervisor.start_game(game_id, player, %GameOptions{
          game_name: game_params["game_name"],
          max_players: 8,
          max_rounds: String.to_integer(game_params["rounds"]),
          bot_count: String.to_integer(game_params["bot_count"])
        })

      {:noreply,
       socket
       |> assign(:me, %{id: socket.assigns.me.id, name: game_params["nickname"]})
       |> put_flash(:info, "Game created!")
       |> push_navigate(to: ~p"/games/#{game_id}")}
    else
      form = to_form(%{changeset | action: :insert})
      {:noreply, assign(socket, changeset: changeset, form: form)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="bg-floating-doodles fixed inset-0 pointer-events-none opacity-20"></div>
    <div class="min-h-screen bg-blue-50 flex items-center justify-center px-4 py-12">
      <div class="w-full max-w-xl bg-white rounded-xl shadow-lg p-8 space-y-8">
        <h2 class="text-3xl font-extrabold text-blue-800 text-center">🎮 Create a New Game</h2>

        <.form for={@form} phx-submit="create_game" class="space-y-6">
          <.input field={@form[:nickname]} type="text" label="Nickname" />
          <.input field={@form[:game_name]} type="text" label="Game Name" />
          <.input field={@form[:rounds]} type="number" label="Number of Rounds" min="1" max="10" />
          <.input field={@form[:bot_count]} type="number" label="Number of bots" min="0" max="10" />
          <.button>
            🚀 Start Game
          </.button>
        </.form>
      </div>
    </div>
    """
  end
end
