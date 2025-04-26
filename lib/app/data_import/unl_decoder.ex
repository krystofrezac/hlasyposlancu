defmodule App.DataImport.UnlDecoder do
  alias App.Logger

  def decode_nullable(value, next_decoder) do
    case value do
      nil -> {:ok, value}
      value -> next_decoder.(value)
    end
  end

  def decode_date(raw) do
    # IT guys probably got bored with only one date format so they added a second one
    # So much fun :)
    [day, month, year] =
      cond do
        String.contains?(raw, ".") ->
          String.split(raw, ".")

        String.contains?(raw, "-") ->
          [year, month, day] = String.split(raw, "-")
          [day, month, year]
      end

    with {day, _remainder} <- Integer.parse(day),
         {month, _remainder} <- Integer.parse(month),
         {year, _remainder} <- Integer.parse(year),
         {:ok, date} <- Date.new(year, month, day) do
      {:ok, date}
    else
      error ->
        Logger.error("Failed to decode date", date: raw, error: error)
        {:error, :invalid_date}
    end
  end

  def decode_integer(raw) do
    case Integer.parse(raw) do
      {int, _remainder} -> {:ok, int}
      :error -> {:error, :invalid_integer}
    end
  end
end
