defmodule App.DataImport.Unl do
  alias App.Logger

  @spec process_unl(
          String.t(),
          (list(String.t() | nil) -> :ok | {:error, reason :: any()})
        ) :: {:ok, processed_rows: integer()} | {:error, reason :: any()}
  def process_unl(path, processor) do
    Logger.info("Starting to process unl file", path: path)

    path
    |> File.stream!()
    |> process_stream(processor)
  end

  defp process_stream(stream, processor) do
    reduce_result =
      Enum.reduce_while(stream, %{row_count: 0, prev_line: nil}, fn line, acc ->
        cond do
          # First line
          acc.prev_line == nil ->
            {:cont, %{row_count: acc.row_count, prev_line: line}}

          # When line starts with `|` it is extension of previous line
          String.starts_with?(line, "|") ->
            {:cont,
             %{
               row_count: acc.row_count,
               prev_line: remove_trailing_delimiter_and_newline(acc.prev_line) <> line
             }}

          true ->
            case process_line(acc.prev_line, processor) do
              {:error, reason} -> {:hatl, {:error, reason}}
              :ok -> {:cont, %{row_count: acc.row_count + 1, prev_line: line}}
            end
        end
      end)

    with %{row_count: row_count, prev_line: prev_line} <- reduce_result,
         :ok <- process_line(prev_line, processor) do
      {:ok, row_count + 1}
    end
  end

  defp process_line(line, processor) do
    decoded_line = :iconv.convert("windows-1250", "utf-8", line)

    decoded_line
    |> remove_trailing_delimiter_and_newline
    |> String.split("|")
    |> nilify_empty_columns()
    |> processor.()
  end

  defp remove_trailing_delimiter_and_newline(line), do: String.replace(line, ~r/\|\n$/, "")

  defp nilify_empty_columns(columns) do
    Enum.map(columns, fn value ->
      case value do
        "" -> nil
        other -> other
      end
    end)
  end
end
