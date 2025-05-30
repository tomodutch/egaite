defmodule Storybook.Components.CoreComponents.Icon do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.CoreComponents.icon/1
  def render_source, do: :function

  def variations do
    [
      %VariationGroup{
        id: :sizes,
        variations: [
          %Variation{
            id: :outline,
            attributes: %{
              name: "hero-book-open",
              class: "dark:text-zinc-300"
            }
          },
          %Variation{
            id: :solid,
            attributes: %{
              name: "hero-book-open-solid",
              class: "dark:text-zinc-300"
            }
          },
          %Variation{
            id: :mini,
            attributes: %{
              name: "hero-book-open-mini",
              class: "dark:text-zinc-300"
            }
          },
          %Variation{
            id: :micro,
            attributes: %{
              name: "hero-book-open-micro",
              class: "dark:text-zinc-300"
            }
          }
        ]
      },
      %VariationGroup{
        id: :colors,
        variations: [
          %Variation{
            id: :indigo,
            attributes: %{
              name: "hero-academic-cap",
              class: "text-indigo-400"
            }
          },
          %Variation{
            id: :pink,
            attributes: %{
              name: "hero-academic-cap",
              class: "text-pink-400"
            }
          },
          %Variation{
            id: :teal,
            attributes: %{
              name: "hero-academic-cap",
              class: "text-teal-400"
            }
          },
          %Variation{
            id: :amber,
            attributes: %{
              name: "hero-academic-cap",
              class: "text-amber-400"
            }
          }
        ]
      },
      %VariationGroup{
        id: :motion,
        template: """
        <div class="py-2" psb-code-hidden>
          <.psb-variation/>
        </div>
        """,
        variations: [
          %Variation{
            id: :spin,
            attributes: %{
              name: "hero-arrow-path",
              class: "motion-safe:animate-spin dark:text-zinc-300"
            }
          },
          %Variation{
            id: :bounce,
            attributes: %{
              name: "hero-arrow-down-circle",
              class: "motion-safe:animate-bounce dark:text-zinc-300"
            }
          },
          %Variation{
            id: :pulse,
            attributes: %{
              name: "hero-information-circle",
              class: "motion-safe:animate-pulse dark:text-zinc-300"
            }
          },
          %Variation{
            id: :ping,
            attributes: %{
              name: "hero-arrows-pointing-out",
              class: "motion-safe:animate-ping dark:text-zinc-300"
            }
          }
        ]
      }
    ]
  end
end
