defmodule App.Parliament do
  alias App.FileStorage

  @voting_url "https://www.psp.cz/eknih/cdrom/opendata/hl-2021ps.zip"

  def import_data() do
    voting_zip_path = "data_import/voting-2021"

    download_voting_data(voting_zip_path)
  end

  defp download_voting_data(into) do
    Req.get(@voting_url, into: FileStorage.stream!(into))
  end
end
