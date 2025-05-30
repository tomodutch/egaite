defmodule Egaite.FuzzyMatcherTest do
  use ExUnit.Case, async: true
  alias Egaite.FuzzyMatcher

  describe "word_in_sentence?/2" do
    test "returns expected results for various inputs" do
      test_cases = [
        # {target, sentence, expected_result, description}
        {"", "", false, "empty strings"},
        {"hello", "hello world", true, "exact match"},
        {"bye", "hello world", false, "no match"},
        {"hello", "helo world", true, "similar word (hello/helo)"},
        {"world", "w0rld", true, "similar word with digit (world/w0rld)"},
        {"test", "tst", true, "similar word (test/tst)"},
        {"Hello", "hello world", true, "case insensitive"},
        {"WORLD", "hello world", true, "case insensitive"},
        {"hello", "hello, world!", true, "handles punctuation"},
        {"hello", "hello world, how are you?", true, "multiple words in sentence"},
        {"world", "hello world, how are you?", true, "multiple words in sentence"},
        {"cat", "car", false, "strict for short words"},
        {"panda", "is it a anda?", true, "partial in sentence"}
      ]

      for {target, sentence, expected, desc} <- test_cases do
        assert FuzzyMatcher.word_in_sentence?(target, sentence) == expected, "Failed for: #{desc}"
      end
    end
  end
end
