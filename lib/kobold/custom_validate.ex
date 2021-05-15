defmodule Kobold.CustomValidate do
  def validate_datetime(datetime) when is_nil(datetime), do: {:ok, nil}
  def validate_datetime(%DateTime{} = datetime), do: {:ok, datetime}
  def validate_datetime(_), do: {:error, "invalid date time"}
end
