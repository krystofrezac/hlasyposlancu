defmodule App.Logger do
  require Logger

  def info(message, args \\ []) do
    format_message(message, args)
    |> Logger.info()
  end

  def error(message, args \\ []) do
    format_message(message, args)
    |> Logger.error()
  end

  defp format_message(message, args), do: [{:message, message} | args]
end
