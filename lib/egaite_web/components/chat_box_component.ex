defmodule EgaiteWeb.ChatBoxComponent do
  use Phoenix.Component

  def chat_box(assigns) do
    ~H"""
    <section class="flex flex-col h-full p-4 bg-gray-50">
      <div id="chat-messages" phx-update="stream" class="flex-grow overflow-auto space-y-2 mb-4">
        <%= for {id, msg} <- @messages do %>
          <p id={"msg-#{id}"}><strong>{msg.name}:</strong> {msg.body}</p>
        <% end %>
      </div>

      <form phx-submit="send_message" id="chatBoxForm" class="flex space-x-2">
        <input
          type="text"
          name="body"
          placeholder="Type a message..."
          class="flex-grow rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
          autocomplete="off"
        />
        <button
          type="submit"
          class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          Send
        </button>
      </form>
    </section>
    """
  end
end
