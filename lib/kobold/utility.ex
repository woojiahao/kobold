defmodule Kobold.Utility do
  @spec shuffle_random(String.t(), number()) :: {:ok, String.t()} | {:error, String.t()}
  def shuffle_random(_block, length) when length <= 0,
    do: {:error, "invalid length provided, provide at least 1 character"}

  def shuffle_random(block, length) do
    str_len = String.length(block)

    if length > str_len do
      {:error, "length of shuffled string cannot be greater than block"}
    else
      indices = generate_indices(str_len, length, [])

      if indices |> Enum.any?(&(&1 >= str_len)) do
        {:error, "invalid index generated"}
      else
        shuffled =
          indices
          |> Enum.map(&String.at(block, &1))
          |> Enum.map(&if &1 == "/", do: ";", else: &1)
          |> Enum.join()

        {:ok, shuffled}
      end
    end
  end

  @spec append(list(), any()) :: list()
  def append(list, value), do: [value | list |> Enum.reverse()] |> Enum.reverse()

  def utc_now(), do: DateTime.utc_now() |> DateTime.truncate(:second)
  def sha256(block), do: :crypto.hash(:sha256, block)

  # Generates a list of random indices based on given size, counting up to max
  defp generate_indices(_max, size, indices) when length(indices) == size, do: indices

  defp generate_indices(max, size, indices) do
    # Not too sure the benefits of using this over Enum.random
    index = :rand.uniform(max) - 1

    if index in indices do
      generate_indices(max, size, indices)
    else
      generate_indices(max, size, append(indices, index))
    end
  end
end
