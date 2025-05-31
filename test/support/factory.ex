defmodule Egaite.TestFactory do
  alias Egaite.{DrawingPrompt, DrawingPromptCategory}

  def build_drawing_prompt_category(attrs \\ %{}) do
    struct(
      DrawingPromptCategory,
      Map.merge(
        %{
          id: "category_#{System.unique_integer([:positive])}",
          name: "Sample Category",
          description: "This is a sample category."
        },
        attrs
      )
    )
  end

  def build_drawing_prompt(attrs \\ %{}) do
    struct(
      DrawingPrompt,
      Map.merge(
        %{
          id: "prompt_#{System.unique_integer([:positive])}",
          text: "Sample Prompt",
          categories: []
        },
        attrs
      )
    )
  end
end
