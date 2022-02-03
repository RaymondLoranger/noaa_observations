defmodule NOAA.Observations.URLTemplates do
  @moduledoc """
  Returns a URL based on URL templates and a station ID or state code.
  """

  @doc """
  Returns a URL based on `url_templates` and a station `id` or state `code`.

  ## Parameters

    - `url_templates` - keyword of EEx strings
    - `options`       - [station: `id`] or [state: `code`]

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
  def url(url_templates, options)

  def url(url_templates, station: id) do
    EEx.eval_string(url_templates[:station], station: id)
  end

  def url(url_templates, state: code) do
    EEx.eval_string(url_templates[:state], state: code)
  end
end
