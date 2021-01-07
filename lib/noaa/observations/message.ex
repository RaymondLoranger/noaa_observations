defmodule NOAA.Observations.Message do
  use PersistConfig

  alias NOAA.Observations.State

  @state_dict get_env(:state_dict)
  @table_spec get_env(:table_spec)

  @spec status(pos_integer) :: String.t()
  def status(301), do: "status code 301 ⇒ Moved Permanently"
  def status(302), do: "status code 302 ⇒ Found"
  def status(403), do: "status code 403 ⇒ Forbidden"
  def status(404), do: "status code 404 ⇒ Not Found"
  def status(code), do: "status code #{code}"

  @spec error(term) :: String.t()
  def error(reason), do: "reason => #{inspect(reason)}"

  @spec error(State.t(), String.t()) :: IO.ANSI.ansilist()
  def error(state, text) do
    [
      [:light_green, "Error fetching NOAA observations for "],
      [:italic, "#{state}...\n"],
      [:light_yellow, text]
    ]
  end

  @spec printing(State.t()) :: IO.ANSI.ansilist()
  def printing(state) do
    [
      @table_spec.left_margin,
      [:light_green, "Printing NOAA observations for "],
      [:italic, "#{@state_dict[state] || "?"}..."]
    ]
  end
end
