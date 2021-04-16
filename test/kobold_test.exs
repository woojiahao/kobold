defmodule KoboldTest do
  use ExUnit.Case
  doctest Kobold

  test "greets the world" do
    assert Kobold.hello() == :world
  end
end
