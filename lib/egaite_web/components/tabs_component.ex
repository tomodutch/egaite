defmodule EgaiteWeb.TabsComponent do
  use Phoenix.Component

  import EgaiteWeb.{
    PlayersListComponent,
    ChatBoxComponent,
    RulesComponent
  }

  attr :active_tab, :string,
    required: true,
    doc: "The currently active tab",
    examples: ["chat", "players", "rules"]

  attr :players, :list,
    default: [],
    doc: "List of players in the game"

  attr :current_artist, :any,
    default: nil,
    doc: "The current artist in the game"

  attr :messages, :list,
    default: [],
    doc: "List of chat messages in the game"

  def tabs_component(assigns) do
    ~H"""
    <div class="md:w-1/3 w-full md:h-full flex flex-col h-1/2">
      <nav class="flex border-b text-sm md:text-base h-12">
        <button phx-click="set_tab" phx-value-tab="chat" class={tab_class(@active_tab, "chat")}>
          Chat
        </button>
        <button phx-click="set_tab" phx-value-tab="players" class={tab_class(@active_tab, "players")}>
          Players
        </button>
        <button phx-click="set_tab" phx-value-tab="rules" class={tab_class(@active_tab, "rules")}>
          Rules
        </button>
      </nav>

      <div class="flex-1 overflow-auto relative">
        <div class={"h-full tab-panel " <> if(@active_tab == "chat", do: "block", else: "hidden")}>
          <.chat_box messages={@messages} />
        </div>
        <div class={"h-full tab-panel " <> if(@active_tab == "players", do: "block", else: "hidden")}>
          <.players_list players={@players} artist={@current_artist} />
        </div>
        <div class={"h-full tab-panel " <> if(@active_tab == "rules", do: "block", else: "hidden")}>
          <.rules />
        </div>
      </div>
    </div>
    """
  end

  def tab_class(active, current) do
    base = "w-full text-center py-2 border-b-2"

    if active == current do
      base <> " border-blue-600 text-blue-600 font-semibold"
    else
      base <> " border-transparent text-gray-500 hover:text-gray-700"
    end
  end
end
