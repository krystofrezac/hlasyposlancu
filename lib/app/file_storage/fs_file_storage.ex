defmodule App.FileStorage.FsFileStorage do
  alias App.FileStorage

  require Logger

  @behaviour FileStorage

  @impl FileStorage
  def stream!(path) do
    path = Path.join(config().base_path, path)
    Logger.debug("Streaming file [#{path}]")

    File.stream!(path)
  end

  @impl FileStorage
  def rm(path) do
    path = Path.join(config().base_path, path)
    Logger.debug("Removing file [#{path}]")

    case File.rm_rf(path) do
      {:ok, _files} -> :ok
      {:error, reason, _files} -> {:error, reason}
    end
  end

  @impl FileStorage
  def exists?(path) do
    path = Path.join(config().base_path, path)
    Logger.debug("Checking that file eixsts [#{path}]")

    File.exists?(path)
  end

  @impl FileStorage
  def mkdir(path) do
    path = Path.join(config().base_path, path)
    Logger.debug("Creating dir [#{path}]")

    File.mkdir(path)
  end

  @impl FileStorage
  def read(path) do
    path = Path.join(config().base_path, path)
    Logger.debug("Reading file [#{path}]")

    File.read(path)
  end

  def path(path) do
    Path.join(config().base_path, path)
  end

  defp config() do
    values = Application.get_env(:app, __MODULE__, [])

    base_path = Keyword.fetch!(values, :base_path)

    %{base_path: base_path}
  end
end
