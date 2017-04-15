
# Exercise in the book "Programming Elixir" by Dave Thomas.

defmodule NOAA.Observations do
  @moduledoc """
  Fetches a list of weather observations from a US state/territory.
  """

  import Logger, only: [info: 1]

  @app           Mix.Project.config[:app]
  @url_templates Application.get_env(@app, :url_templates)

  @doc """
  Fetches weather observations from a US `state`/territory.

  Returns a tuple of either `{:ok, [observation]}` or `{:error, text}`.

  ## Parameters

    - `state`   - US state/territory code
    - `options` - URL templates (keyword)

  ## Options

    - `:url_templates` - defaults to config value `:url_templates` (map)

  ## Examples

      alias NOAA.Observations
      Observations.fetch("vt")
  """
  @spec fetch(String.t, Keyword.t) :: {:ok, [map]} | {:error, String.t}
  def fetch(state, options \\ []) do
    info "Fetching NOAA Observations from state/territory: #{state}..."
    with url_templates <- Keyword.get(options, :url_templates, @url_templates),
        url_templates <- Map.merge(@url_templates, url_templates),
        {:ok, stations} <- stations(state, url_templates) do
      stations
      |> Enum.map(&observation &1, url_templates)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> case do
        %{error: errors} -> {:error, List.first errors}
        %{ok: observations} -> {:ok, observations}
        %{} -> {:error, "unknown error"}
      end
    end
  end

  @doc """
  Fetches a list of station IDs for a US `state`/territory.

  Returns a tuple of either `{:ok, [station_id]}` or `{:error, text}`.

  ## Parameters

    - `state`         - US state/territory code (string)
    - `url_templates` - URL templates (map)

  ## Examples

      alias NOAA.Observations
      app = Mix.Project.config[:app]
      url_templates = Application.get_env(app, :url_templates)
      Observations.stations("vt", url_templates)
  """
  @spec stations(String.t, map) :: {:ok, [String.t]} | {:error, String.t}
  def stations(state, %{state: url_template}) do
    try do
      with url <- url(url_template, state: state),
          {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url) do
        {
          :ok,
          # <a href="display.php?stid=(KCDA)">Caledonia County Airport</a>
          ~r[<a href=".*?stid=(.*?)">.*?</a>] # capture station ID
          |> Regex.scan(body, capture: :all_but_first) # i.e. only subpattern
          |> List.flatten # each item is [station_id]
        }
      else
        {:ok, %{status_code: 301}} -> {:error, "status code: 301 (not found)"}
        {:ok, %{status_code: 302}} -> {:error, "status code: 302 (not found)"}
        {:ok, %{status_code: 404}} -> {:error, "status code: 404 (not found)"}
        {:error, %{reason: reason}} -> {:error, "reason: #{inspect reason}"}
        any -> {:error, "unknown: #{inspect any}"}
      end
    rescue
      error -> {:error, "exception: #{Exception.message error}"}
    end
  end

  @doc """
  Fetches the latest observation for a given NOAA `station` ID.

  Returns a tuple of either `{:ok, observation}` or `{:error, text}`.

  ## Parameters

    - `station`       - NOAA station ID (string)
    - `url_templates` - URL templates (map)

  ## Examples

      alias NOAA.Observations
      app = Mix.Project.config[:app]
      url_templates = Application.get_env(app, :url_templates)
      Observations.observation("KBTV", url_templates)
  """
  @spec observation(String.t, map) :: {:ok, map} | {:error, String.t}
  def observation(station, %{station: url_template}) do
    try do
      with url <- url(url_template, station: station),
          {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url) do
        {
          :ok,
          # <(weather)>(Fog)</weather>
          ~r{<([^/][^>]+)>(.*?)</\1>} # capture XML tag and value
          |> Regex.scan(body, capture: :all_but_first) # i.e. only subpatterns
          |> Map.new(&List.to_tuple &1) # &1 is [tag, value]
        }
      else
        {:ok, %{status_code: 301}} -> {:error, "status code: 301 (not found)"}
        {:ok, %{status_code: 302}} -> {:error, "status code: 302 (not found)"}
        {:ok, %{status_code: 404}} -> {:error, "status code: 404 (not found)"}
        {:error, %{reason: reason}} -> {:error, "reason: #{inspect reason}"}
        any -> {:error, "unknown: #{inspect any}"}
      end
    rescue
      error -> {:error, "exception: #{Exception.message error}"}
    end
  end

  @doc """
  Returns a URL based on the given `station` ID or `state` code.

  ## Parameters

    - `url_template` - URL template
    - `keyword`      - [station: `station`] or [state: `state`]

  ## Examples

      iex> alias NOAA.Observations
      iex> app = Mix.Project.config[:app]
      iex> %{station: url_template} = Application.get_env(app, :url_templates)
      iex> Observations.url(url_template, station: "KBTV")
      "http://w1.weather.gov/xml/current_obs/KBTV.xml"

      iex> alias NOAA.Observations
      iex> app = Mix.Project.config[:app]
      iex> %{state: url_template} = Application.get_env(app, :url_templates)
      iex> Observations.url(url_template, state: "vt")
      "http://w1.weather.gov/xml/current_obs/seek.php?state=vt&Find=Find"

      iex> alias NOAA.Observations
      iex> url_template = "https://weather.gc.ca/forecast/canada/" <>
      ...>   "index_e.html?id=<st>"
      iex> Observations.url(url_template, state: "qc")
      "https://weather.gc.ca/forecast/canada/index_e.html?id=qc"
  """
  @spec url(String.t, Keyword.t) :: String.t
  def url(url_template, station: station) do
    String.replace(url_template, ~r/{stn}|<stn>/, station)
  end
  def url(url_template, state: state) do
    String.replace(url_template, ~r/{st}|<st>/, state)
  end
end
