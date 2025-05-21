defmodule Egaite.Games do
  def list_active_games do
    Registry.select(Egaite.GameRegistry, [
      {
        {:"$1", :"$2", :_},
        [{:is_pid, :"$2"}],
        [:"$1"]
      }
    ])
  end
end
