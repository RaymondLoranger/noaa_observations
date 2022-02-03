defmodule NOAA.Observations.State do
  @moduledoc """
  Fetches the stations for a US state/territory code.
  """

  alias NOAA.Observations.{Log, Message, Station, URLTemplates}

  @typedoc "US state/territory code"
  @type code :: String.t()

  @doc """
  Fetches the stations for a US state/territory `code`.

  Returns a tuple of either `{:ok, station_names}` or `{:error, text}`.

  ## Parameters

    - `code`          - US state/territory code
    - `url_templates` - URL templates

  ## Examples

      iex> alias NOAA.Observations.State
      iex> url_templates = [
      ...>   state:
      ...>     "https://w1.weather.gov/xml/current_obs/seek.php?state=" <>
      ...>       "<%=state%>&Find=Find"
      ...> ]
      iex> {:ok, stations} = State.stations("vt", url_templates)
      iex> %{"KFSO" => name} = Map.new(stations)
      iex> name
      "Franklin County State Airport"

      iex> alias NOAA.Observations.State
      iex> url_templates = [
      ...>   state:
      ...>     "http://w1.weather.gov/xml/current_obs/seek.php?state=" <>
      ...>       "<%=state%>&Find=Find"
      ...> ]
      iex> {:error, text} = State.stations("vt", url_templates)
      iex> text
      "status code 301 ⇒ Moved Permanently"

      iex> alias NOAA.Observations.State
      iex> url_templates = [
      ...>   state:
      ...>     "https://www.weather.gov/xml/current_obs/seek.php?state=" <>
      ...>       "<%=state%>&Find=Find"
      ...> ]
      iex> {:error, text} = State.stations("vt", url_templates)
      iex> text
      "status code 302 ⇒ Found"

      iex> alias NOAA.Observations.State
      iex> url_templates = [
      ...>   state:
      ...>     "https://w1.weather.gov/xml/past_obs/seek.php?state=" <>
      ...>       "<%=state%>&Find=Find"
      ...> ]
      iex> {:error, text} = State.stations("vt", url_templates)
      iex> text
      "status code 404 ⇒ Not Found"

      iex> alias NOAA.Observations.State
      iex> url_templates = [
      ...>   state:
      ...>     "htp://w1.weather.gov/xml/current_obs/seek.php?state=" <>
      ...>       "<%=state%>&Find=Find"
      ...> ]
      iex> {:error, text} = State.stations("vt", url_templates)
      iex> text
      "reason => :nxdomain"

      iex> alias NOAA.Observations.State
      iex> url_templates = [state: "http://localhost:1"]
      iex> {:error, text} = State.stations("vt", url_templates)
      iex> text
      "reason => :econnrefused"
  """
  @spec stations(code, Keyword.t()) ::
          {:ok, [Station.t]} | {:error, String.t()}
  def stations(code, url_templates) do
    url = URLTemplates.url(url_templates, state: code)
    :ok = Log.info(:fetching_stations, {code, url, __ENV__})

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {
          :ok,
          ~r[<a href=".*?stid=(.*?)">(.*?)</a>] # capture station ID and name
          |> Regex.scan(body, capture: :all_but_first) # i.e. only subpatterns
          |> Enum.map(&List.to_tuple/1) # each [id, name] -> {id, name}
        }

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, Message.status(code)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, Message.error(reason)}
    end
  end
end
