defmodule EgaiteWeb.InitAssigns do
  import Phoenix.Component
  alias Egaite.Player

  def on_mount(:default, _params, %{"player" => %{"id" => id, "name" => name}}, socket) do
    player = %Player{id: id, name: name}
    {:cont, assign(socket, :me, player)}
  end
end
