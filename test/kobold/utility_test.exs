defmodule Kobold.UtilityTest do
  use ExUnit.Case
  import Kobold.Utility

  describe "testing shuffle_random" do
    setup do
      # Ensures that the first random number is always the same
      :rand.seed(:exro928ss, 1..16 |> Enum.to_list() |> Enum.map(&((&1 + 15) * 17 - 11)))
      []
    end

    test "length cannot be < 0" do
      {status, _} = shuffle_random("foo", -1)
      assert status == :error
    end

    test "length cannot be == 0" do
      {status, _} = shuffle_random("foo", 0)
      assert status == :error
    end

    test "length cannot be > input string length" do
      {status, _} = shuffle_random("foo", 4)
      assert status = :error
    end

    test "shuffled string replaces / with ;" do
      test = "a/8s7"
      assert shuffle_random(test, String.length(test)) == {:ok, "a8s7;"}
    end

    test "shuffle_random('abc123', 5) shuffles to 'ac312'" do
      assert shuffle_random("abc123", 5) == {:ok, "ac312"}
    end

    test "shuffle_random('s58bo7l3', 6) shuffles to 's837b5'" do
      assert shuffle_random("s58bo7l3", 6) == {:ok, "s837b5"}
    end
  end
end
