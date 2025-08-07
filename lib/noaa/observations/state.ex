defmodule NOAA.Observations.State do
  @moduledoc """
  Fetches the stations for a US state/territory code.
  """

  alias NOAA.Observations.{Log, Message, Station, TemplatesAgent}

  @typedoc "US state/territory code"
  @type code :: <<_::16>>
  @typedoc "Erroneous state"
  @type error :: map

  @doc """
  Fetches the stations for a `state_code`.

  Returns a tuple of either `{:ok, [station]}` or `{:error, error_code, text}`.

  ## Parameters

    - `state_code` - US state/territory code

  ## Examples

      iex> alias NOAA.Observations.{State, TemplatesAgent}
      iex> :ok = TemplatesAgent.refresh()
      iex> {:ok, stations} = State.stations("VT")
      iex> %{"KFSO" => name} = Map.new(stations)
      iex> name
      "Franklin County State Airport"

      iex> alias NOAA.Observations.{State, TemplatesAgent}
      iex> template =
      ...>   "http://forecast.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> State.stations("VT")
      {:error, 301, "Moved Permanently"}

      iex> alias NOAA.Observations.{State, TemplatesAgent}
      iex> template =
      ...>   "https://www.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> State.stations("VT")
      {:error, 302, "Found (Moved Temporarily)"}

      iex> alias NOAA.Observations.{State, TemplatesAgent}
      iex> template =
      ...>   "https://forecast.weather.gov/xml/past_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> State.stations("VT")
      {:error, 404, "Not Found"}

      iex> alias NOAA.Observations.{State, TemplatesAgent}
      iex> template =
      ...>   "htp://forecast.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> State.stations("VT")
      {:error, :nxdomain, "Non-Existent Domain"}

      iex> alias NOAA.Observations.{State, TemplatesAgent}
      iex> template = "http://localhost:65535"
      iex> TemplatesAgent.update_state_template(template)
      iex> State.stations("VT")
      {:error, :econnrefused, "Connection Refused By Server"}

      iex> alias NOAA.Observations.{State, TemplatesAgent}
      iex> template = "http://localhost:0"
      iex> TemplatesAgent.update_state_template(template)
      iex> State.stations("VT")
      {:error, :eaddrnotavail, "Address Not Available"}
  """
  @spec stations(code) :: {:ok, [Station.t()]} | {:error, any, String.t()}
  def stations(state_code) do
    state_url = TemplatesAgent.state_url(state_code: state_code)
    args = {state_code, state_url, __ENV__}

    case HTTPoison.get(state_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        :ok = Log.info(:stations_fetched, args)
        {:ok, _stations(body)}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        error_text = Message.status(status_code)
        args = {args, {status_code, error_text}}
        :ok = Log.error(:stations_not_fetched, args)
        {:error, status_code, error_text}

      {:error, %HTTPoison.Error{reason: reason}} ->
        error_text = Message.error(reason)
        args = {args, {reason, error_text}}
        :ok = Log.error(:stations_not_fetched, args)
        {:error, reason, error_text}
    end
  end

  ## Private functions

  @spec _stations(String.t()) :: [Station.t()]
  defp _stations(body) do
    # <a href="/xml/current_obs/display.php?stid=KTIX">Titusville</a>
    # capture station ID and name
    ~r[<a href=".*?stid=(\w+)">(.*?)</a>]
    # i.e. only captured subpatterns
    |> Regex.scan(body, capture: :all_but_first)
    # each [id, name] -> {id, name}
    |> Enum.map(&List.to_tuple/1)
  end
end
