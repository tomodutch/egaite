defmodule EgaiteWeb.GameNotFoundLive do
  use EgaiteWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, full_screen: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-floating-doodles fixed inset-0 pointer-events-none opacity-20"></div>
    <div class="min-h-screen bg-blue-50 flex items-center justify-center px-4 py-12">
      <div class="w-full max-w-xl bg-white rounded-xl shadow-lg p-8 space-y-6 text-center">
        <h1 class="text-3xl font-extrabold text-blue-800">Game Not Found</h1>
        <p class="text-blue-700 text-lg">
          The game you're looking for doesn't exist or has already ended.
        </p>
        <.link navigate={~p"/"} class="text-blue-600 hover:underline text-sm">
          ⬅ Back to Home
        </.link>
      </div>
    </div>
    """
  end
end
