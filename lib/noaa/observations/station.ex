defmodule NOAA.Observations.Station do
  @moduledoc """
  Fetches the latest observation for a given NOAA station.
  """

  use PersistConfig

  alias NOAA.Observations.{Log, Message, State, TemplatesAgent}

  @typedoc "Station ID"
  @type id :: <<_::32>>
  @typedoc "Station name"
  @type name :: String.t()
  @typedoc "NOAA weather observation"
  @type observation :: map
  @typedoc "Erroneous station"
  @type error :: map
  @typedoc "NOAA station"
  @type t :: {id, name}

  @doc """
  Fetches the latest observation for a given NOAA `station`.

  Returns either tuple `{:ok, observation}` or tuple `{:error, error}`.

  ## Parameters

    - `{station_id, station_name}` - NOAA station
    - `state_code`                 - US state/territory code

  ## Examples

      iex> alias NOAA.Observations.{Station, TemplatesAgent}
      iex> :ok = TemplatesAgent.refresh()
      iex> {:ok, observation} =
      ...>   Station.observation({"KFSO", "KFSO name"}, "VT")
      iex> is_map(observation) and is_binary(observation["wind_mph"])
      true

      iex> alias NOAA.Observations.{Station, TemplatesAgent}
      iex> template =
      ...>   "htp://forecast.weather.gov/xml/current_obs" <>
      ...>     "/display.php?stid=<%=station_id%>"
      iex> TemplatesAgent.update_station_template(template)
      iex> {:error, %{error_text: text, error_code: code, station_id: id}} =
      ...>   Station.observation({"KFSO", "KFSO name"}, "VT")
      iex> {text, code, id}
      {"Non-Existent Domain", :nxdomain, "KFSO"}

      iex> alias NOAA.Observations.{Station, TemplatesAgent}
      iex> template =
      ...>   "https://forecast.weather.gov/xml/past_obs" <>
      ...>     "/display.php?stid=<%=station_id%>"
      iex> TemplatesAgent.update_station_template(template)
      iex> {:error, %{error_text: text, error_code: code, station_id: id}} =
      ...>   Station.observation({"KFSO", "KFSO name"}, "VT")
      iex> {text, code, id}
      {"Not Found", 404, "KFSO"}
  """
  @spec observation(t, State.code()) :: {:ok, observation} | {:error, error}
  def observation({station_id, station_name} = _station, state_code) do
    station_url = TemplatesAgent.station_url(station_id: station_id)

    case HTTPoison.get(station_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        :ok =
          Log.info(
            :observation_fetched,
            {station_id, station_name, state_code, station_url, __ENV__}
          )

        {
          :ok,
          # <weather>Fog</weather> or <weather> Rain</weather>
          # capture XML tag and value
          ~r{<([^/][^>]+)>\s*(.*?)</\1>}
          # i.e. only subpatterns
          |> Regex.scan(body, capture: :all_but_first)
          # each [tag, value] -> {tag, value}
          |> Map.new(&List.to_tuple/1)
        }

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        error_text = Message.status(status_code)

        :ok =
          Log.error(
            :observation_not_fetched,
            {station_id, station_name, state_code, status_code, error_text,
             station_url, __ENV__}
          )

        {:error,
         %{
           station_id: station_id,
           station_name: station_name,
           error_code: status_code,
           error_text: error_text,
           station_url: station_url
         }}

      {:error, %HTTPoison.Error{reason: reason}} ->
        error_text = Message.error(reason)

        :ok =
          Log.error(
            :observation_not_fetched,
            {station_id, station_name, state_code, reason, error_text,
             station_url, __ENV__}
          )

        {:error,
         %{
           station_id: station_id,
           station_name: station_name,
           error_code: reason,
           error_text: error_text,
           station_url: station_url
         }}
    end
  end
end
