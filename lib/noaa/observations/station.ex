defmodule NOAA.Observations.Station do
  @moduledoc """
  Fetches the latest observation for a given NOAA station.
  """

  alias NOAA.Observations.{Log, Message, State, URLTemplates}

  @typedoc "Station ID"
  @type id :: String.t()
  @typedoc "Station name"
  @type name :: String.t()
  @typedoc "NOAA weather observation"
  @type observation :: map
  @typedoc "NOAA station"
  @type t :: {id, name}

  @doc """
  Fetches the latest observation for a given NOAA `station`.

  Returns either tuple `{:ok, observation}` or tuple `{:error, text}`.

  ## Parameters

    - `{id, name}`    - NOAA station
    - `url_templates` - URL templates

  ## Examples

      iex> alias NOAA.Observations.Station
      iex> url_templates = [
      ...>   station:
      ...>     "https://w1.weather.gov/xml/current_obs/display.php?stid=" <>
      ...>       "<%=station%>"
      ...> ]
      iex> {:ok, observation} =
      ...>   Station.observation({"KFSO", "KFSO name"}, "vt", url_templates)
      iex> is_map(observation) and
      ...> is_binary(observation["temp_c"]) and
      ...> is_binary(observation["wind_mph"])
      true

      iex> alias NOAA.Observations.Station
      iex> url_templates = [
      ...>   station:
      ...>     "htp://w1.weather.gov/xml/current_obs/display.php?stid=" <>
      ...>       "<%=station%>"
      ...> ]
      iex> {:error, text} =
      ...>   Station.observation({"KFSO", "KFSO name"}, "vt", url_templates)
      iex> text
      "reason => :nxdomain"

      iex> alias NOAA.Observations.Station
      iex> url_templates = [
      ...>   station:
      ...>     "https://w1.weather.gov/xml/past_obs/display.php?stid=" <>
      ...>       "<%=station%>"
      ...> ]
      iex> {:error, text} =
      ...>   Station.observation({"KFSO", "KFSO name"}, "vt", url_templates)
      iex> text
      "status code 404 ⇒ Not Found"
  """
  @spec observation(t, State.code, Keyword.t()) ::
          {:ok, observation} | {:error, String.t()}
  def observation({id, name} = _station, code, url_templates) do
    url = URLTemplates.url(url_templates, station: id)
    :ok = Log.info(:fetching_observation, {id, name, code, url, __ENV__})

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {
          :ok,
          # <weather>Fog</weather>
          ~r{<([^/][^>]+)>(.*?)</\1>} # capture XML tag and value
          |> Regex.scan(body, capture: :all_but_first) # i.e. only subpatterns
          |> Map.new(&List.to_tuple/1) # each [tag, value] -> {tag, value}
        }

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, Message.status(code)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, Message.error(reason)}
    end
  end
end
