defmodule EgaiteWeb.GameCreateLive do
  use EgaiteWeb, :live_view

  alias Egaite.{
    GameForm,
    GameSupervisor,
    GameOptions,
    Player,
    DrawingPromptCategory,
    DrawingPrompt,
    Repo
  }

  def mount(_params, _session, socket) do
    categories = Repo.all(DrawingPromptCategory)

    changeset =
      GameForm.changeset(
        %GameForm{
          nickname: socket.assigns.me.name,
          game_name: "New Game",
          rounds: 4,
          bot_count: 0,
          category_ids: Enum.map(categories, & &1.id)
        },
        %{}
      )

    socket =
      socket
      |> assign(full_screen: true)
      |> assign(:categories, categories)
      |> assign(:changeset, changeset)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  def handle_event("create_game", %{"game_form" => game_params}, socket) do
    changeset = GameForm.changeset(%GameForm{}, game_params)

    if changeset.valid? do
      game_id = Ecto.UUID.generate()
      player = %Player{id: socket.assigns.me.id, name: game_params["nickname"]}

      category_ids = game_params["category_ids"] || []

      # Fetch prompts associated with selected categories
      prompts =
        DrawingPrompt
        |> Repo.all()
        |> Repo.preload(:categories)
        |> Enum.filter(fn prompt ->
          Enum.any?(prompt.categories, fn cat -> cat.id in category_ids end)
        end)

      {:ok, _} =
        GameSupervisor.start_game(game_id, player, %GameOptions{
          game_name: game_params["game_name"],
          max_players: 8,
          max_rounds: String.to_integer(game_params["rounds"]),
          bot_count: String.to_integer(game_params["bot_count"]),
          prompts: prompts
        })

      {:noreply,
       socket
       |> assign(:me, %{id: socket.assigns.me.id, name: game_params["nickname"]})
       |> put_flash(:info, "Game created!")
       |> push_navigate(to: ~p"/games/#{game_id}")}
    else
      {:noreply,
       assign(socket,
         changeset: %{changeset | action: :insert},
         form: to_form(%{changeset | action: :insert})
       )}
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
          <.input field={@form[:bot_count]} type="number" label="Number of Bots" min="0" max="10" />

          <div class="space-y-2">
            <label class="text-sm font-medium text-gray-700">Categories</label>
            <div class="grid grid-cols-2 gap-2">
              <%= for category <- @categories do %>
                <label class="flex items-center space-x-2">
                  <input
                    type="checkbox"
                    name="game_form[category_ids][]"
                    value={category.id}
                    checked={category.id in @form[:category_ids].value}
                  />
                  <span><%= category.name %></span>
                </label>
              <% end %>
            </div>
          </div>

          <.button>
            🚀 Start Game
          </.button>
        </.form>
      </div>
    </div>
    """
  end
end
