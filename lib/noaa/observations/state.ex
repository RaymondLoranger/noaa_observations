defmodule NOAA.Observations.State do
  @moduledoc """
  Fetches the stations for a US state/territory code.
  """

  use PersistConfig

  alias NOAA.Observations.{Log, Message, Station, URL}

  @templates get_env(:url_templates)

  @typedoc "US state/territory code"
  @type code :: <<_::16>>
  @typedoc "Faulty state"
  @type fault :: map

  @doc """
  Fetches the stations for a `state_code`.

  Returns a tuple of either `{:ok, [station]}` or `{:error, error_code, text}`.

  ## Parameters

    - `state_code` - US state/territory code
    - `template`   - URL template

  ## Examples

      iex> alias NOAA.Observations.State
      iex> {:ok, stations} = State.stations("VT")
      iex> %{"KFSO" => name} = Map.new(stations)
      iex> name
      "Franklin County State Airport"

      iex> alias NOAA.Observations.State
      iex> template =
      ...>   "http://forecast.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> State.stations("VT", template)
      {:error, 301, "Moved Permanently"}

      iex> alias NOAA.Observations.State
      iex> template =
      ...>   "https://www.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> State.stations("VT", template)
      {:error, 302, "Found (Moved Temporarily)"}

      iex> alias NOAA.Observations.State
      iex> template =
      ...>   "https://forecast.weather.gov/xml/past_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> State.stations("VT", template)
      {:error, 404, "Not Found"}

      iex> alias NOAA.Observations.State
      iex> template =
      ...>   "htp://forecast.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> State.stations("VT", template)
      {:error, :nxdomain, "Non-Existent Domain"}

      iex> alias NOAA.Observations.State
      iex> template = "http://localhost:65535"
      iex> State.stations("VT", template)
      {:error, :econnrefused, "Connection Refused By Server"}

      iex> alias NOAA.Observations.State
      iex> template = "http://localhost:65536"
      iex> State.stations("VT", template)
      {:error, :checkout_failure, "Checkout Failure"}
  """
  @spec stations(code, URL.template()) ::
          {:ok, [Station.t()]} | {:error, any, String.t()}
  def stations(state_code, template \\ @templates.state) do
    state_url = URL.for_state(state_code, template)

    case HTTPoison.get(state_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        :ok = Log.info(:stations_fetched, {state_code, state_url, __ENV__})

        {
          :ok,
          # <a href="/xml/current_obs/display.php?stid=KTIX">Titusville</a>
          # capture station ID and name
          ~r[<a href=".*?stid=(.*?)">(.*?)</a>]
          # i.e. only subpatterns
          |> Regex.scan(body, capture: :all_but_first)
          # each [id, name] -> {id, name}
          |> Enum.map(&List.to_tuple/1)
        }

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        error_text = Message.status(status_code)

        :ok =
          Log.error(
            :stations_not_fetched,
            {state_code, state_url, status_code, error_text, __ENV__}
          )

        {:error, status_code, error_text}

      {:error, %HTTPoison.Error{reason: reason}} ->
        error_text = Message.error(reason)

        :ok =
          Log.error(
            :stations_not_fetched,
            {state_code, state_url, reason, error_text, __ENV__}
          )

        {:error, reason, error_text}
    end
  end
end
