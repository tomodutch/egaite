defmodule Storybook.Components.CoreComponents.Back do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.CoreComponents.back/1
  def render_source, do: :function

  def template do
    """
    <div class="-mt-16 py-8" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          navigate: "/storybook"
        },
        slots: [
          "Back to home page"
        ]
      }
    ]
  end
end
