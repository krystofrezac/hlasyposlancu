defmodule App.DataImport.Unl do
  alias App.Logger

  def download(url, zip_path, unzip_path) do
    with :ok <- rm_existing_file(zip_path),
         :ok <- rm_existing_file(unzip_path),
         {:ok, _res} <- Req.get(url, into: File.stream!(zip_path)),
         :ok <- unzip(zip_path, unzip_path) do
      :ok
    end
  end

  def remove(zip_path, unzip_path) do
    with :ok <- rm_existing_file(zip_path),
         :ok <- rm_existing_file(unzip_path) do
      :ok
    end
  end

  defp unzip(from, to) do
    :ok = File.mkdir(to)

    from = from |> String.to_charlist()
    to = to |> String.to_charlist()

    Logger.info("Unzipping from", from: from, to: to)

    case :zip.unzip(from, [{:cwd, to}]) do
      {:ok, _file_list} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to unzip archive", from: from, to: to, reason: reason)
        {:error, reason}
    end
  end

  defp rm_existing_file(path) do
    case File.exists?(path) do
      true ->
        case File.rm_rf(path) do
          {:ok, _removed_files} ->
            :ok

          {:error, reason, _file} ->
            Logger.error("Failed to remove existing file", path: path, reason: reason)
            {:error, reason}
        end

      false ->
        :ok
    end
  end

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

  @spec process_with_count_check(
          String.t(),
          (list(String.t() | nil) -> :ok | {:error, reason :: any()}),
          (-> integer())
        ) :: {:ok, processed_rows: integer()} | {:error, reason :: any()}
  def process_with_count_check(path, processor, count_db_rows) do
    with {:ok, processed_rows} <- process_unl(path, processor) do
      db_rows = count_db_rows.()

      case processed_rows == db_rows do
        true ->
          :ok

        false ->
          Logger.error(
            "Number of processed rows do not equal number of rows in DB",
            processed_rows: processed_rows,
            db_rows: db_rows,
            file: path
          )

          {:error, :number_of_rows_do_not_match}
      end
    end
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
              {:error, reason} -> {:halt, {:error, reason}}
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
