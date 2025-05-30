defmodule Storybook.Components.CoreComponents.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.CoreComponents.button/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          type: "button",
          class: "bg-emerald-400 hover:bg-emerald-500 text-emerald-800"
        },
        slots: [
          "Click me!"
        ]
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "button",
          disabled: true
        },
        slots: [
          "Click me!"
        ]
      }
    ]
  end
end
