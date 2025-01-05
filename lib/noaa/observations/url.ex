defmodule NOAA.Observations.URL do
  @moduledoc """
  Returns a URL based on either a state code or a station ID and a URL template.
  """

  use PersistConfig

  alias NOAA.Observations.{State, Station}

  @templates get_env(:url_templates)

  @typedoc "URL"
  @type t :: String.t()
  @typedoc "URL template"
  @type template :: String.t()

  @doc """
  Returns a URL based on `state_code` and `template`.

  ## Examples

      iex> alias NOAA.Observations.URL
      iex> URL.for_state("VT")
      "https://forecast.weather.gov/xml/current_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations.URL
      iex> template = "http://noaa.gov/seek.php?state=<%=state_code%>&Find=Find"
      iex> URL.for_state("VT", template)
      "http://noaa.gov/seek.php?state=VT&Find=Find"
  """
  @spec for_state(State.code(), template) :: t
  def for_state(state_code, template \\ @templates.state) do
    EEx.eval_string(template, state_code: state_code)
  end

  @doc """
  Returns a URL based on `station_id` and `template`.

  ## Examples

      iex> alias NOAA.Observations.URL
      iex> URL.for_station("KBTV")
      "https://forecast.weather.gov/xml/current_obs/display.php?stid=KBTV"

      iex> alias NOAA.Observations.URL
      iex> tpl = "https://noaa.gov/current/display.php?stid=<%=station_id%>"
      iex> URL.for_station("KFSO", tpl)
      "https://noaa.gov/current/display.php?stid=KFSO"
  """
  @spec for_station(Station.id(), template) :: t
  def for_station(station_id, template \\ @templates.station) do
    EEx.eval_string(template, station_id: station_id)
  end
end
