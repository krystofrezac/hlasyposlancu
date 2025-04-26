defmodule App.FileStorage do
  @callback stream!(path :: String.t()) :: File.Stream.t()
  @callback rm(path :: String.t()) :: :ok | {:error, reason :: any()}
  @callback exists?(path :: String.t()) :: :boolean
  @callback mkdir(path :: String.t()) :: :ok | {:error, reason :: any()}
  @callback read(path :: String.t()) :: :ok | {:error, reason :: any()}

  def stream!(path), do: impl().stream!(path)
  def rm(path), do: impl().rm(path)
  def exists?(path), do: impl().exists?(path)
  def mkdir(path), do: impl().mkdir(path)
  def read(path), do: impl().mkdir(path)

  defp impl(), do: Application.get_env(:app, __MODULE__, App.FileStorage.FsFileStorage)
end
