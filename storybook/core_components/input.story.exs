defmodule Storybook.Components.CoreComponents.Input do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.CoreComponents.input/1
  def render_source, do: :function
  def layout, do: :one_column

  def template do
    """
    <.form for={%{}} class="w-full space-y-6" psb-code-hidden>
      <.psb-variation-group />
    </.form>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :text,
        variations: [
          %Variation{
            id: :default,
            attributes: %{
              label: "Text input",
              name: "default",
              value: "some text",
              type: "text"
            }
          },
          %Variation{
            id: :errors,
            attributes: %{
              label: "Input with errors",
              name: "text_errors",
              value: "invalid value",
              errors: ["This field is invalid"]
            }
          }
        ]
      },
      %Variation{
        id: :select,
        attributes: %{
          label: "Select list",
          name: "checkbox",
          type: "select",
          value: "user",
          options: [Admin: "admin", User: "user"]
        }
      },
      %VariationGroup{
        id: :checkbox,
        variations: [
          %Variation{
            id: :opt1,
            attributes: %{
              label: "Option 1",
              name: "checkbox",
              type: "checkbox",
              checked: true
            }
          },
          %Variation{
            id: :opt2,
            attributes: %{
              label: "Option 2",
              name: "checkbox",
              type: "checkbox",
              checked: false
            }
          }
        ]
      },
      %Variation{
        id: :area,
        attributes: %{
          label: "Text area",
          name: "textarea",
          type: "textarea",
          value: "user"
        }
      },
      %VariationGroup{
        id: :type,
        description: "Various input types",
        variations:
          for type <- ~w(number range email password tel search month week date time color file) do
            %Variation{
              id: String.to_atom(type),
              attributes: %{
                type: type,
                name: type,
                label: String.capitalize(type),
                value: type
              }
            }
          end
      }
    ]
  end
end
