defmodule App.FileStorage do
  def path(path) do
    Path.join(config().base_path, path)
  end

  defp config() do
    values = Application.get_env(:app, __MODULE__, [])

    base_path = Keyword.fetch!(values, :base_path)

    %{base_path: base_path}
  end
end
