defmodule Egaite.TestHelpers do
  defmacro assert_eventually(do: block) do
    quote do
      Enum.reduce_while(1..10, nil, fn _, _acc ->
        try do
          result = unquote(block)
          {:halt, result}
        rescue
          _ ->
            Process.sleep(20)
            {:cont, nil}
        end
      end)
      |> case do
        nil ->
          flunk("Expected condition to eventually be true (after 10 attempts)")

        value ->
          value
      end
    end
  end
end
