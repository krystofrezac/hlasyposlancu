defmodule App.FileStorage.FsFileStorage do
  alias App.FileStorage

  @behaviour FileStorage

  @impl FileStorage
  def stream!(name) do
    Path.join(config().base_path, name)
    |>IO.inspect()
    |> File.stream!()
  end

  defp config() do
    values = Application.get_env(:app, __MODULE__, [])

    base_path = Keyword.fetch!(values, :base_path)

    %{base_path: base_path}
  end
end
