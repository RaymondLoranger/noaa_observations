defmodule NOAA.Observations.State do
  @moduledoc """
  Fetches the stations for a US `state`/territory.
  """

  alias NOAA.Observations.{Log, Message, Station, URLTemplates}

  @type t :: String.t()

  @doc """
  Fetches the stations for a US `state`/territory.

  Returns a tuple of either `{:ok, station_dict}` or `{:error, text}`.

  ## Parameters

    - `state`         - US state/territory code
    - `url_templates` - URL templates

  ## Examples

      iex> alias NOAA.Observations.State
      iex> url_templates = [
      ...>   state:
      ...>     "https://w1.weather.gov/xml/current_obs/seek.php?state=" <>
      ...>       "<%=state%>&Find=Find"
      ...> ]
      iex> {:ok, %{"KFSO" => name}} = State.stations("vt", url_templates)
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
  @spec stations(t, Keyword.t()) ::
          {:ok, Station.dict()} | {:error, String.t()}
  def stations(state, url_templates) do
    url = URLTemplates.url(url_templates, state: state)
    :ok = Log.info(:fetching_stations, {state, url, __ENV__})

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {
          :ok,
          # <a href="display.php?stid=KCDA">Caledonia County Airport</a>
          ~r[<a href=".*?stid=(.*?)">(.*?)</a>] # capture station and name
          |> Regex.scan(body, capture: :all_but_first) # i.e. only subpatterns
          |> Map.new(&List.to_tuple/1) # each [station, name] -> {station, name}
        }

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, Message.status(code)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, Message.error(reason)}
    end
  end
end
