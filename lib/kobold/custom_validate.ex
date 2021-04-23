defmodule Kobold.CustomValidate do
  def validate_datetime(%DateTime{} = datetime), do: {:ok, datetime}
  def validate_datetime(_), do: {:error, "invalid date time"}
end
