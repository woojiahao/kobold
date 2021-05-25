defmodule Kobold.Exception do
  defmodule DuplicateHashException do
    defexception message: "Hash cannot be duplicated"
  end
end
