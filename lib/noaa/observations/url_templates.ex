defmodule NOAA.Observations.URLTemplates do
  @moduledoc """
  Returns a URL based on `url_templates` and `station` or `state`.
  """

  @doc """
  Returns a URL based on `url_templates` and `station` or `state`.

  ## Parameters

    - `url_templates` - keyword of EEx strings
    - `keyword`       - [station: `station`] or [state: `state`]

  ## Examples

      iex> alias NOAA.Observations.URLTemplates
      iex> url_templates = [
      ...>  state: "w1.weather.gov/seek.php?state=<%=state%>&Find=Find",
      ...>  station: "w1.weather.gov/display.php?stid=<%=station%>"
      ...> ]
      iex> {URLTemplates.url(url_templates, state: "vt"),
      ...>  URLTemplates.url(url_templates, station: "KBTV")}
      {"w1.weather.gov/seek.php?state=vt&Find=Find",
       "w1.weather.gov/display.php?stid=KBTV"}

      iex> alias NOAA.Observations.URLTemplates
      iex> url_templates = [
      ...>   state: "weather.gc.ca/forecast/canada/index_e.html?id=<%=state%>"
      ...> ]
      iex> URLTemplates.url(url_templates, state: "qc")
      "weather.gc.ca/forecast/canada/index_e.html?id=qc"
  """
  @spec url(Keyword.t(), Keyword.t()) :: String.t()
  def url(url_templates, station: station) do
    EEx.eval_string(url_templates[:station], station: station)
  end

  def url(url_templates, state: state) do
    EEx.eval_string(url_templates[:state], state: state)
  end
end
