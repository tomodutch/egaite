defmodule EgaiteWeb.ChatBoxComponent do
  use Phoenix.Component

  @moduledoc """
  A UI component rendering a chat box interface.

  This component displays a list of chat messages and an input form to send new messages.

  ## Assigns

    * `:messages` - A list or enumerable of `{id, message}` tuples, where `message` is a map with `:name` and `:body` keys.

  ## Example usage

      <.chat_box messages={@messages} />
  """
  attr :messages, :list,
    required: true,
    doc: "List of {id, message} tuples where message is a map with :name and :body keys"

  def chat_box(assigns) do
    ~H"""
    <section class="flex flex-col h-full p-4 bg-gray-50">
      <!-- Messages: flex-grow and scroll -->
      <div
        id="chat-messages"
        phx-update="stream"
        phx-hook="AutoScroll"
        class="flex-grow overflow-auto space-y-2 mb-4"
      >
        <%= for {id, msg} <- @messages do %>
          <p id={"msg-#{id}"}><strong>{msg.name}:</strong> {msg.body}</p>
        <% end %>
      </div>

    <!-- Input form sticks to bottom -->
      <form phx-submit="send_message" id="chatBoxForm" class="flex space-x-2" style="flex-shrink: 0;">
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
