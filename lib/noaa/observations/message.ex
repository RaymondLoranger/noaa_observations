defmodule NOAA.Observations.Message do
  use PersistConfig

  alias NOAA.Observations.State

  @state_names get_env(:state_names)
  @table_spec get_env(:table_spec)

  @spec status(pos_integer) :: String.t()
  def status(301), do: "status code 301 ⇒ Moved Permanently"
  def status(302), do: "status code 302 ⇒ Found"
  def status(403), do: "status code 403 ⇒ Forbidden"
  def status(404), do: "status code 404 ⇒ Not Found"
  def status(code), do: "status code #{code}"

  @spec error(term) :: String.t()
  def error(reason), do: "reason => #{inspect(reason)}"

  @spec writing_table(State.code()) :: :ok
  def writing_table(code) do
    [
      @table_spec.left_margin,
      [:white, "Writing table of weather observations for "],
      [:light_white, "#{@state_names[code] || "???"}..."]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  @spec fetching_error(State.code(), String.t()) :: :ok
  def fetching_error(code, text) do
    [
      [:white, "Error fetching weather observations of "],
      [:light_white, "#{@state_names[code] || "???"}..."],
      [:light_yellow, :string.titlecase(text)]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end
end
