defmodule App.DataImport do
  alias App.DataImport.Unl
  alias App.DataImport.UnlDecoder
  alias App.Logger
  alias App.Parliament
  alias App.FileStorage

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

  defp process_voting([
         id,
         body_id,
         _meeting_number,
         _number,
         point,
         date,
         time,
         voted_for,
         voted_against,
         abstained,
         did_not_vote,
         logged_in,
         quorum,
         voting_type,
         result,
         title_long,
         title_short
       ]) do
    voting_type =
      case voting_type do
        "N" ->
          {:ok, :normal}

        "R" ->
          {:ok, :manual}

        "E" ->
          {:ok, :error}

        _ ->
          Logger.error("Got unknown voting_type", voting_type: voting_type)
          :error
      end

    result =
      case result do
        "A" ->
          {:ok, :approved}

        "R" ->
          {:ok, :rejected}

        "X" ->
          {:ok, :unknown}

        "Q" ->
          {:ok, :not_public}

        "K" ->
          {:ok, :quorum_not_reached}

        _ ->
          Logger.error("Got unknown result", result: result)
          :error
      end

    with {:ok, id} <- UnlDecoder.decode_integer(id),
         {:ok, body_id} <- UnlDecoder.decode_integer(body_id),
         {:ok, point} <- UnlDecoder.decode_integer(point),
         {:ok, date_time} <- UnlDecoder.decode_naive_date_time(date, time),
         {:ok, voted_for} <- UnlDecoder.decode_integer(voted_for),
         {:ok, voted_against} <- UnlDecoder.decode_integer(voted_against),
         {:ok, abstained} <- UnlDecoder.decode_integer(abstained),
         {:ok, did_not_vote} <- UnlDecoder.decode_integer(did_not_vote),
         {:ok, logged_in} <- UnlDecoder.decode_integer(logged_in),
         {:ok, quorum} <- UnlDecoder.decode_integer(quorum),
         {:ok, voting_type} <- voting_type,
         {:ok, result} <- result do
      upsert_result =
        Parliament.upsert_voting(%{
          id: id,
          body_id: body_id,
          point: point,
          date_time: date_time,
          voted_for: voted_for,
          voted_against: voted_against,
          abstained: abstained,
          did_not_vote: did_not_vote,
          logged_in: logged_in,
          quorum: quorum,
          voting_type: voting_type,
          result: result,
          title: title_long || title_short
        })

      case upsert_result do
        {:ok, voting} ->
          Logger.info("Upserted voting", voting: voting)
          :ok

        {:error, changeset} ->
          Logger.error("Failed to upsert voting with errors", errors: changeset.errors)
          {:error, changeset}
      end
    end
  end

  defp import_general(zip_url) do
    zip_path = FileStorage.path("data_import/general.zip")
    unzip_path = FileStorage.path("data_import/general")

    result =
      with :ok <- Unl.download(zip_url, zip_path, unzip_path),
           :ok <-
             Unl.process_with_count_check(
               Path.join(unzip_path, "osoby.unl"),
               &process_person/1,
               &Parliament.count_person/0
             ),
           :ok <-
             Unl.process_with_count_check(
               Path.join(unzip_path, "poslanec.unl"),
               &process_deputy/1,
               &Parliament.count_deputy/0
             ),
           :ok <-
             Unl.process_with_count_check(
               Path.join(unzip_path, "organy.unl"),
               &process_body/1,
               &Parliament.count_body/0
             ) do
        :ok
      end

    :ok = Unl.remove(zip_path, unzip_path)
    result
  end

  defp import_election_period(zip_url, start_year) do
    unzip_path = FileStorage.path("data_import/voting" <> start_year)
    zip_path = unzip_path <> ".zip"

    result =
      with :ok <- Unl.download(zip_url, zip_path, unzip_path),
           :ok <-
             Unl.process_with_count_check(
               Path.join(unzip_path, "hl#{start_year}s.unl"),
               &process_voting/1,
               &Parliament.count_voting/0
             ) do
        :ok
      end

    :ok = Unl.remove(zip_path, unzip_path)
    result
  end
end
