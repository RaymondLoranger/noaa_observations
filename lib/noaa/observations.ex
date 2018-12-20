# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations do
  @moduledoc """
  Fetches a list of weather observations for a US state/territory.
  """

  use PersistConfig

  alias NOAA.Observations.CLI

  require Logger

  @typep obs :: map

  @url_templates Application.get_env(@app, :url_templates)

  @doc """
  Fetches weather observations for a US `state`/territory.

  Returns a tuple of either `{:ok, [obs]}` or `{:error, text}`.

  ## Parameters

    - `state`         - US state/territory code
    - `url_templates` - URL templates

  ## URL templates

    - `:state`   - URL template for a state
    - `:station` - URL template for a station

  ## Examples

      alias NOAA.Observations
      Observations.fetch("vt")
  """
  @spec fetch(CLI.state(), Keyword.t()) :: {:ok, [obs]} | {:error, String.t()}
  def fetch(state, url_templates \\ @url_templates) do
    Logger.info("Fetching NOAA Observations for state/territory: #{state}...")

    with url_templates <- Keyword.merge(@url_templates, url_templates),
         {:ok, stations} <- stations(state, url_templates) do
      stations
      |> Stream.map(&obs(&1, url_templates))
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> case do
        %{error: errors} -> {:error, List.first(errors)}
        %{ok: observations} -> {:ok, observations}
      end
    end
  end

  @doc """
  Fetches a list of stations for a US `state`/territory.

  Returns a tuple of either `{:ok, [stn]}` or `{:error, text}`.

  ## Parameters

    - `state`         - US state/territory code
    - `url_templates` - URL templates
  """
  @spec stations(CLI.state(), Keyword.t()) ::
          {:ok, [CLI.stn()]} | {:error, String.t()}
  def stations(state, url_templates) do
    try do
      with url <- url(url_templates[:state], state: state),
           {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url) do
        {
          :ok,
          # <a href="display.php?stid=(KCDA)">Caledonia County Airport</a>
          ~r[<a href=".*?stid=(.*?)">.*?</a>] # capture station
          |> Regex.scan(body, capture: :all_but_first) # i.e. only subpattern
          |> List.flatten() # each item is [stn]
        }
      else
        {:ok, %{status_code: code}} -> {:error, status(code)}
        {:error, %{reason: reason}} -> {:error, error(reason)}
        unknown -> {:error, error(unknown)}
      end
    rescue
      exception -> {:error, error(exception)}
    end
  end

  @doc """
  Fetches the latest observation for a given NOAA `station`.

  Returns a tuple of either `{:ok, obs}` or `{:error, text}`.

  ## Parameters

    - `station`       - NOAA station
    - `url_templates` - URL templates
  """
  @spec obs(CLI.stn(), Keyword.t()) :: {:ok, obs} | {:error, String.t()}
  def obs(station, url_templates) do
    try do
      with url <- url(url_templates[:station], station: station),
           {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url) do
        {
          :ok,
          # <(weather)>(Fog)</weather>
          ~r{<([^/][^>]+)>(.*?)</\1>} # capture XML tag and value
          |> Regex.scan(body, capture: :all_but_first) # i.e. only subpatterns
          |> Map.new(&List.to_tuple/1) # arg is [tag, value]
        }
      else
        {:ok, %{status_code: code}} -> {:error, status(code)}
        {:error, %{reason: reason}} -> {:error, error(reason)}
        unknown -> {:error, error(unknown)}
      end
    rescue
      exception -> {:error, error(exception)}
    end
  end

  ## Private functions

  @spec status(pos_integer) :: String.t
  defp status(301), do: "status code: 301 ⇒ Moved Permanently"
  defp status(302), do: "status code: 302 ⇒ Found"
  defp status(404), do: "status code: 404 ⇒ Not Found"
  defp status(code), do: "status code: #{code}"

  @spec error(term) :: String.t
  defp error(reason), do: "reason: #{inspect(reason)}"

  # @doc """
  # Returns a URL based on the given `station` or `state` code.

  # ## Parameters

  #   - `url_template` - URL template
  #   - `keyword`      - [station: `station`] or [state: `state`]

  # ## Examples

  #     iex> alias NOAA.Observations
  #     iex> app = Mix.Project.config[:app]
  #     iex> url_templates = Application.get_env(app, :url_templates)
  #     iex> Observations.url(url_templates[:station], station: "KBTV")
  #     "http://w1.weather.gov/xml/current_obs/KBTV.xml"

  #     iex> alias NOAA.Observations
  #     iex> app = Mix.Project.config[:app]
  #     iex> url_templates = Application.get_env(app, :url_templates)
  #     iex> Observations.url(url_templates[:state], state: "vt")
  #     "http://w1.weather.gov/xml/current_obs/seek.php?state=vt&Find=Find"

  #     iex> alias NOAA.Observations
  #     iex> url_template =
  #     ...>   "https://weather.gc.ca/forecast/canada/index_e.html?id=<st>"
  #     iex> Observations.url(url_template, state: "qc")
  #     "https://weather.gc.ca/forecast/canada/index_e.html?id=qc"
  # """
  @spec url(String.t(), Keyword.t()) :: String.t()
  defp url(url_template, station: station) do
    String.replace(url_template, ~r/{stn}|<stn>/, station)
  end

  defp url(url_template, state: state) do
    String.replace(url_template, ~r/{st}|<st>/, state)
  end
end
