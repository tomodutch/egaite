defmodule Storybook.Components.CoreComponents.Header do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.CoreComponents.header/1
  def imports, do: [{EgaiteWeb.CoreComponents, button: 1}]
  def render_source, do: :function

  def template do
    """
    <div class="w-full" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "With a title",
        slots: [
          "Section title"
        ]
      },
      %Variation{
        id: :subtitle,
        description: "With a subtitle",
        slots: [
          "Section title",
          """
          <:subtitle>
            Here a subtitle
          </:subtitle>
          """
        ]
      },
      %Variation{
        id: :actions,
        description: "With a subtitle and actions",
        slots: [
          "Section title",
          """
          <:subtitle>
            Here a subtitle
          </:subtitle>
          """,
          """
          <:actions>
            <.button>Action!</.button>
          </:actions>
          """
        ]
      }
    ]
  end
end
