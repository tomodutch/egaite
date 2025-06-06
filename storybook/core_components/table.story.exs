defmodule Storybook.Components.CoreComponents.Table do
  use PhoenixStorybook.Story, :component

  def function, do: &EgaiteWeb.CoreComponents.table/1
  def imports, do: [{EgaiteWeb.CoreComponents, button: 1}]
  def render_source, do: :function
  def layout, do: :one_column

  def template do
    """
    <div class="w-4/5 mb-4" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          rows: table_rows()
        },
        slots: table_slots()
      },
      %Variation{
        id: :with_function,
        description: "Applying functions to row items",
        attributes: %{
          rows: table_rows(),
          row_id: {:eval, ~S|&"user-#{&1.id}"|},
          row_item: {:eval, ~S"&%{&1 | last_name: String.upcase(&1.last_name)}"}
        },
        slots: table_slots()
      },
      %Variation{
        id: :with_actions,
        description: "With an action slot",
        attributes: %{
          rows: table_rows()
        },
        slots: [
          """
          <:action>
            <.button>Show</.button>
          </:action>
          """
          | table_slots()
        ]
      }
    ]
  end

  defp table_rows do
    [
      %{id: 1, first_name: "Jean", last_name: "Dupont", city: "Paris"},
      %{id: 2, first_name: "Sam", last_name: "Smith", city: "NY"}
    ]
  end

  defp table_slots do
    [
      """
      <:col :let={user} label="ID">
        <%= user.id %>
      </:col>
      """,
      """
      <:col :let={user} label="First name">
        <%= user.first_name %>
      </:col>
      """,
      """
      <:col :let={user} label="Last name">
        <%= user.last_name %>
      </:col>
      """,
      """
      <:col :let={user} label="City">
        <%= user.city %>
      </:col>
      """
    ]
  end
end
