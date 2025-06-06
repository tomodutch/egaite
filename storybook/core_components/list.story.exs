defmodule Storybook.Components.CoreComponents.List do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.CoreComponents.list/1
  def render_source, do: :function

  def template do
    """
    <div class="-mt-14 py-8" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        slots: [
          ~s|<:item title="Apples">two</:item>|,
          ~s|<:item title="Bananas">five</:item>|,
          ~s|<:item title="Carrots">a lot</:item>|,
          ~s|<:item title="Potatoes">even more</:item>|
        ]
      }
    ]
  end
end
