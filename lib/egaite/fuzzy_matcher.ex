defmodule Egaite.FuzzyMatcher do
  @moduledoc """
  Determines if a target word is present in a sentence using Levenshtein distance,
  with stricter thresholds for short words.
  """

  @doc """
  Returns true if the target word approximately matches any word in the sentence.
  """
  def word_in_sentence?(target, sentence) do
    target = String.downcase(target)
    words = String.downcase(sentence) |> String.split(~r/\W+/, trim: true)

    Enum.any?(words, fn word -> similar?(target, word) end)
  end

  defp similar?(w1, w2) when w1 == w2, do: true

  defp similar?(w1, w2) do
    len = max(String.length(w1), String.length(w2))
    dist = Levenshtein.distance(w1, w2)

    allowed_distance = max_distance(len)
    dist <= allowed_distance
  end

  defp max_distance(len) when len <= 3, do: 0
  defp max_distance(len) when len <= 4, do: 1
  defp max_distance(len) when len <= 6, do: 1
  defp max_distance(len) when len <= 8, do: 2
  defp max_distance(_), do: 3
end
