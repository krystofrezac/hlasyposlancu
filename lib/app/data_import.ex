defmodule App.DataImport do
  alias App.DataImport.Unl
  alias App.DataImport.UnlDecoder
  alias App.Logger
  alias App.Parliament
  alias App.FileStorage.FsFileStorage

  @voting_url "https://www.psp.cz/eknih/cdrom/opendata/hl-2021ps.zip"
  @general_url "https://www.psp.cz/eknih/cdrom/opendata/poslanci.zip"

  @spec import_data() :: :ok | {:error, reason :: any()}
  def import_data() do
    with :ok <- import_general(@general_url),
         :ok <- import_election_period(@voting_url, "2021") do
      :ok
    end
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

    with {:ok, id} <- UnlDecoder.decode_integer(id),
         {:ok, birth_date} <- UnlDecoder.decode_nullable(birth_date, &UnlDecoder.decode_date/1),
         {:ok, updated_at} <- UnlDecoder.decode_nullable(updated_at, &UnlDecoder.decode_date/1),
         {:ok, died_at} <- UnlDecoder.decode_nullable(death_at, &UnlDecoder.decode_date/1) do
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
    with {:ok, id} <- UnlDecoder.decode_integer(id),
         {:ok, person_id} <- UnlDecoder.decode_integer(person_id) do
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
    with {:ok, id} <- UnlDecoder.decode_integer(id),
         {:ok, from} <- UnlDecoder.decode_date(from),
         {:ok, to} <- UnlDecoder.decode_nullable(to, &UnlDecoder.decode_date/1) do
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

  defp process_voting([]) do
  end

  defp import_general(zip_url) do
    zip_path = "data_import/general.zip"
    unzip_path = "data_import/general"

    with :ok <- rm_existing_file(zip_path),
         :ok <- rm_existing_file(unzip_path),
         {:ok, _res} <- download_data(zip_url, zip_path),
         :ok <- unzip(zip_path, unzip_path),
         :ok <-
           process_unl_with_count_check(
             Path.join(unzip_path, "osoby.unl"),
             &process_person/1,
             &Parliament.count_person/0
           ),
         :ok <-
           process_unl_with_count_check(
             Path.join(unzip_path, "poslanec.unl"),
             &process_deputy/1,
             &Parliament.count_deputy/0
           ),
         :ok <-
           process_unl_with_count_check(
             Path.join(unzip_path, "organy.unl"),
             &process_body/1,
             &Parliament.count_body/0
           ),
         :ok <- rm_existing_file(zip_path),
         :ok <- rm_existing_file(unzip_path) do
      :ok
    end
  end

  defp import_election_period(zip_url, start_year) do
    unzip_path = "data_import/voting" <> start_year
    zip_path = unzip_path <> ".zip"

    with :ok <- rm_existing_file(zip_path),
         :ok <- rm_existing_file(unzip_path),
         {:ok, _res} <- download_data(zip_url, zip_path),
         :ok <- unzip(zip_path, unzip_path),
         :ok <-
           process_unl_with_count_check(
             # TODO:
             Path.join(unzip_path, "hl_xxx"),
             &process_voting/1,
             fn -> 0 end
           ),
         :ok <- rm_existing_file(zip_path),
         :ok <- rm_existing_file(unzip_path) do
      :ok
    end
  end

  defp process_unl_with_count_check(path, processor, count_db_rows) do
    full_path = FsFileStorage.path(path)

    with {:ok, processed_rows} <- Unl.process_unl(full_path, processor) do
      db_rows = count_db_rows.()

      case processed_rows == db_rows do
        true ->
          :ok

        false ->
          Logger.error(
            "Number of processed rows do not equal number of rows in DB",
            processed_rows: processed_rows,
            db_rows: db_rows,
            file: full_path
          )

          {:error, :number_of_rows_do_not_match}
      end
    end
  end

  defp download_data(url, into) do
    Req.get(url, into: FsFileStorage.stream!(into))
  end

  defp unzip(from, to) do
    FsFileStorage.mkdir(to)

    from = from |> FsFileStorage.path() |> String.to_charlist()
    to = to |> FsFileStorage.path() |> String.to_charlist()

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
    case FsFileStorage.exists?(path) do
      true ->
        case FsFileStorage.rm(path) do
          :ok ->
            :ok

          {:error, reason} ->
            Logger.error("Failed to remove existing file", path: path, reason: reason)
            {:error, reason}
        end

      false ->
        :ok
    end
  end
end
