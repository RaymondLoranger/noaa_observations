defmodule NOAA.Observations.Station do
  @moduledoc """
  Fetches the latest observation for a given NOAA `station`.
  """

  alias NOAA.Observations.{Log, Message, URLTemplates}

  @type dict :: %{t => name}
  @type name :: String.t()
  @type obs :: map
  @type t :: String.t()

  @doc """
  Fetches the latest observation for a given NOAA `station`.

  Returns a tuple of either `{:ok, obs}` or `{:error, text}`.

  ## Parameters

    - `{station, name}` - NOAA station
    - `url_templates`   - URL templates

  ## Examples

      iex> alias NOAA.Observations.Station
      iex> url_templates = [
      ...>   station:
      ...>     "https://w1.weather.gov/xml/current_obs/display.php?stid=" <>
      ...>       "<%=station%>"
      ...> ]
      iex> {:ok, obs} = Station.obs({"KFSO", "KFSO name"}, url_templates)
      iex> is_map(obs) and
      ...> is_binary(obs["temp_c"]) and is_binary(obs["wind_mph"])
      true

      iex> alias NOAA.Observations.Station
      iex> url_templates = [
      ...>   station:
      ...>     "htp://w1.weather.gov/xml/current_obs/display.php?stid=" <>
      ...>       "<%=station%>"
      ...> ]
      iex> {:error, text} = Station.obs({"KFSO", "KFSO name"}, url_templates)
      iex> text
      "reason => :nxdomain"

      iex> alias NOAA.Observations.Station
      iex> url_templates = [
      ...>   station:
      ...>     "https://w1.weather.gov/xml/past_obs/display.php?stid=" <>
      ...>       "<%=station%>"
      ...> ]
      iex> {:error, text} = Station.obs({"KFSO", "KFSO name"}, url_templates)
      iex> text
      "status code 404 ⇒ Not Found"
  """
  @spec obs({t, name}, Keyword.t()) :: {:ok, obs} | {:error, String.t()}
  def obs({station, name}, url_templates) do
    url = URLTemplates.url(url_templates, station: station)
    :ok = Log.info(:fetching_observation, {station, name, url, __ENV__})

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
