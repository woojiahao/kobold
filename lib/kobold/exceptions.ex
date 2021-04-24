defmodule Kobold.DuplicateHashException do
  defexception []

  def message(%{}) do
    "hash cannot be duplicated"
  end
end
