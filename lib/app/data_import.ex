defmodule App.DataImport do
  alias App.Logger
  alias App.Parliament
  alias App.FileStorage.FsFileStorage

  @voting_url "https://www.psp.cz/eknih/cdrom/opendata/hl-2021ps.zip"
  @general_url "https://www.psp.cz/eknih/cdrom/opendata/poslanci.zip"

  def import_data() do
    general_zip_path = "data_import/general.zip"
    general_unziped_path = "data_import/general"
    voting_zip_path = "data_import/voting-2021.zip"
    voting_unziped_path = "data_import/voting-2021"

    :ok = rm_existing_file(general_zip_path)
    :ok = rm_existing_file(general_unziped_path)
    :ok = rm_existing_file(voting_zip_path)
    :ok = rm_existing_file(voting_unziped_path)

    res =
      with {:download_general, {:ok, _res}} <-
             download_data(@general_url, general_zip_path)
             |> name_stage(:download_general),
           {:download_voting, {:ok, _res}} <-
             download_data(@voting_url, voting_zip_path)
             |> name_stage(:download_voting),
           {:unzip_general, {:ok, _file_names}} <-
             unzip(general_zip_path, general_unziped_path)
             |> name_stage(:unzip_general),
           {:unzip_voting, {:ok, _file_names}} <-
             unzip(voting_zip_path, voting_unziped_path)
             |> name_stage(:unzip_voting),
           {:import_person, :ok} <-
             read_and_decode_unl(
               Path.join(general_unziped_path, "osoby.unl"),
               &process_person/1,
               &Parliament.count_person/0
             )
             |> name_stage(:import_person),
           {:import_deputy, :ok} <-
             read_and_decode_unl(
               Path.join(general_unziped_path, "poslanec.unl"),
               &process_deputy/1,
               &Parliament.count_deputy/0
             )
             |> name_stage(:import_deputy),
           {:import_body, :ok} <-
             read_and_decode_unl(
               Path.join(general_unziped_path, "organy.unl"),
               &process_body/1,
               &Parliament.count_body/0
             )
             |> name_stage(:import_body) do
        :ok
      else
        {stage, err} ->
          Logger.error("Stage failed", stage: stage, err: err)
          err
      end

    :ok = rm_existing_file(general_zip_path)
    :ok = rm_existing_file(general_unziped_path)
    :ok = rm_existing_file(voting_zip_path)
    :ok = rm_existing_file(voting_unziped_path)
    res
  end

  defp process_person([
         id,
         before_title,
         first_name,
         last_name,
         after_title,
         birth_date,
         sex,
         updated_at,
         death_at
       ]) do
    sex =
      case sex do
        "M" -> :male
        _ -> :female
      end

    with {:ok, id} <- decode_integer(id),
         {:ok, birth_date} <- decode_nullable(birth_date, &decode_date/1),
         {:ok, updated_at} <- decode_nullable(updated_at, &decode_date/1),
         {:ok, died_at} <- decode_nullable(death_at, &decode_date/1) do
      upsert_result =
        Parliament.upsert_person(%{
          id: id,
          before_title: before_title,
          first_name: first_name,
          last_name: last_name,
          after_title: after_title,
          birth_date: birth_date,
          sex: sex,
          updated_at: updated_at,
          died_at: died_at
        })

      case upsert_result do
        {:ok, person} ->
          Logger.info("Upserted person", person: person)
          :ok

        {:error, changeset} ->
          Logger.error("Failed to upsert person with errors", errors: changeset.errors)
          {:error, changeset}
      end
    end
  end

  defp process_deputy([
         id,
         person_id,
         _region_id,
         _slate_id,
         _term_id,
         _web,
         _street,
         _city,
         _zip,
         _email,
         _phone_number,
         _fax,
         _official_phone_number,
         _facebook,
         _photo
       ]) do
    with {:ok, id} <- decode_integer(id),
         {:ok, person_id} <- decode_integer(person_id) do
      upsert_result = Parliament.upsert_deputy(%{id: id, person_id: person_id})

      case upsert_result do
        {:ok, deputy} ->
          Logger.info("Upserted deputy", deputy: deputy)
          :ok

        {:error, changeset} ->
          Logger.error("Failed to upsert deputy with errors", errors: changeset.errors)
          {:error, changeset}
      end
    end
  end

  defp process_body([
         id,
         _parent_id,
         _type_id,
         abbreviation,
         name,
         _name_english,
         from,
         to,
         _priority,
         _base
       ]) do
    with {:ok, id} <- decode_integer(id),
         {:ok, from} <- decode_date(from),
         {:ok, to} <- decode_nullable(to, &decode_date/1) do
      upsert_result =
        Parliament.upsert_body(%{
          id: id,
          abbreviation: abbreviation,
          name: name,
          from: from,
          to: to
        })

      case upsert_result do
        {:ok, body} ->
          Logger.info("Upserted body", body: body)
          :ok

        {:error, changeset} ->
          Logger.error("Failed to upsert body with errors", errors: changeset.errors)
          {:error, changeset}
      end
    end
  end

  defp decode_nullable(value, next_decoder) do
    case value do
      nil -> {:ok, value}
      value -> next_decoder.(value)
    end
  end

  defp decode_date(raw) do
    # It guys probably got bored with only one date format so they added a second one
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

  defp decode_integer(raw) do
    case Integer.parse(raw) do
      {int, _remainder} -> {:ok, int}
      :error -> {:error, :invalid_integer}
    end
  end

  @spec read_and_decode_unl(
          String.t(),
          (list(String.t() | nil) -> :ok | {:error, reason :: any()}),
          (-> integer())
        ) :: :ok | {:error, reason :: any()}
  defp read_and_decode_unl(path, process_row, count_db_rows) do
    process_line = fn line ->
      decoded_line = :iconv.convert("windows-1250", "utf-8", line)

      decoded_line
      |> remove_trailing_delimiter_and_newline
      |> String.split("|")
      |> Enum.map(fn value ->
        case value do
          "" -> nil
          other -> other
        end
      end)
      |> process_row.()
    end

    process_result =
      path
      |> FsFileStorage.path()
      |> File.stream!()
      |> Enum.reduce_while(%{row_count: 0, prev_line: nil}, fn line, acc ->
        cond do
          acc.prev_line == nil ->
            {:cont, %{row_count: acc.row_count, prev_line: line}}

          String.starts_with?(line, "|") ->
            {:cont,
             %{
               row_count: acc.row_count,
               prev_line: remove_trailing_delimiter_and_newline(acc.prev_line) <> line
             }}

          true ->
            case process_line.(acc.prev_line) do
              {:error, reason} -> {:hatl, {:error, reason}}
              :ok -> {:cont, %{row_count: acc.row_count + 1, prev_line: line}}
            end
        end
      end)

    # TODO: error handling
    process_line.(process_result.prev_line)

    case process_result do
      {:error, reason} ->
        {:error, reason}

      %{row_count: processed_rows} ->
        db_row_count = count_db_rows.()

        # Because of the last process_line call
        processed_rows = processed_rows + 1

        case processed_rows == db_row_count do
          true ->
            :ok

          false ->
            Logger.error(
              "Number of rows do not equal number of rows in DB",
              processed_rows: processed_rows,
              db_rows: db_row_count,
              path: path
            )

            {:error, :number_of_rows_do_not_match}
        end
    end
  end

  defp remove_trailing_delimiter_and_newline(line), do: String.replace(line, ~r/\|\n$/, "")

  defp download_data(url, into) do
    Req.get(url, into: FsFileStorage.stream!(into))
  end

  defp unzip(from, to) do
    FsFileStorage.mkdir(to)

    from = from |> FsFileStorage.path() |> String.to_charlist()
    to = to |> FsFileStorage.path() |> String.to_charlist()

    Logger.info("Unzipping from", from: from, to: to)

    :zip.unzip(from, [{:cwd, to}])
  end

  defp rm_existing_file(path) do
    case FsFileStorage.exists?(path) do
      true -> FsFileStorage.rm(path)
      false -> :ok
    end
  end

  defp name_stage(result, name), do: {name, result}
end
