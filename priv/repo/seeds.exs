alias Egaite.Repo
alias Egaite.{DrawingPromptCategory, DrawingPrompt}

categories = [
  %{name: "Animals", description: "All kinds of animals"},
  %{name: "Food", description: "Fruits, vegetables, and more"},
  %{name: "Sports", description: "Various sports and athletes"}
]

animal_prompts = [
  "Cat",
  "Dog",
  "Elephant",
  "Giraffe",
  "Monkey",
  "Rabbit",
  "Dolphin",
  "Turtle",
  "Lion",
  "Panda",
  "Snake"
]

prompts =
  [
    %{text: "Pizza", category_names: ["Food"]},
    %{text: "Soccer", category_names: ["Sports"]},
    %{text: "Basketball", category_names: ["Sports"]}
  ] ++ Enum.map(animal_prompts, fn animal ->
    %{text: animal, category_names: ["Animals"]}
  end)

# Insert categories if they don't already exist
category_map =
  categories
  |> Enum.map(fn cat ->
    Repo.get_by(DrawingPromptCategory, name: cat.name) ||
      Repo.insert!(DrawingPromptCategory.changeset(%DrawingPromptCategory{}, cat))
  end)
  |> Enum.reduce(%{}, fn cat, acc -> Map.put(acc, cat.name, cat) end)

# Insert prompts if they don't already exist
Enum.each(prompts, fn %{text: text, category_names: category_names} ->
  unless Repo.get_by(DrawingPrompt, text: text) do
    categories = Enum.map(category_names, &Map.get(category_map, &1))

    changeset =
      %DrawingPrompt{}
      |> DrawingPrompt.changeset(%{text: text})
      |> Ecto.Changeset.put_assoc(:categories, categories)

    Repo.insert!(changeset)
  end
end)
