defmodule Egaite.GameSupervisorTest do
  alias Egaite.{GameSupervisor, Player}
  use ExUnit.Case

  test "should start a game" do
    assert {:ok, _pid} = GameSupervisor.start_game("1", %Player{id: "2"})
  end

  test "should list all games" do

  end
end
