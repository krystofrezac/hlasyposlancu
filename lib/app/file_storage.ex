defmodule App.FileStorage do
  @callback stream!(name :: String.t()) :: File.Stream.t()

  def stream!(name), do: impl().stream!(name)

  defp impl(), do: Application.get_env(:app, __MODULE__, App.FileStorage.FsFileStorage)
end
