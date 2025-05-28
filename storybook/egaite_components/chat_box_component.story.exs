defmodule EgaiteWeb.ChatBoxComponentStory do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.ChatBoxComponent.chat_box/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          messages: [
            {1, %{body: "Hello, world!", name: "Alice"}},
            {2, %{body: "This is a test message.", name: "Bob"}},
            {3, %{body: "Phoenix Storybook is awesome!", name: "Charlie"}}
          ]
        },
        slots: []
      },
      %Variation{
        id: :without_messages,
        attributes: %{
          messages: []
        },
        slots: []
      }
    ]
  end
end
