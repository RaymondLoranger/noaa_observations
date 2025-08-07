# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations do
  @moduledoc """
  Fetches weather observations for a US state/territory code.
  """

  use PersistConfig
  use File.Only.Logger

  alias __MODULE__.{Log, Message, State, Station, TemplatesAgent}
  alias IO.ANSI.Table

  @fetches_left get_env(:fetches_left)
  @state_names get_env(:state_names)
  @timeout_spec get_env(:timeout_spec)
  @wait 400

  @typedoc "A map of station observations/errors"
  @type t :: %{
          optional(:ok) => [Station.observation()],
          optional(:error) => [Station.error()]
        }

  @doc """
  Fetches weather observations for a `state_code`.

  ## Parameters

    - `state_code` - US state/territory code

  ## Examples

      iex> alias NOAA.Observations
      iex> alias NOAA.Observations.TemplatesAgent
      iex> :ok = TemplatesAgent.refresh()
      iex> %{ok: observations} = Observations.fetch("VT")
      iex> Enum.all?(observations, &is_map/1) and length(observations) > 0
      true

      iex> alias NOAA.Observations
      iex> alias NOAA.Observations.TemplatesAgent
      iex> template =
      ...>   "http://forecast.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> {:error,
      ...>  %{
      ...>    error_code: 301,
      ...>    error_text: "Moved Permanently",
      ...>    state_url: url
      ...>  }} = Observations.fetch("VT")
      iex> url
      "http://forecast.weather.gov/xml/current_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations
      iex> alias NOAA.Observations.TemplatesAgent
      iex> template =
      ...>   "https://www.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> {:error,
      ...>  %{
      ...>    error_code: 302,
      ...>    error_text: "Found (Moved Temporarily)",
      ...>    state_url: url
      ...>  }} = Observations.fetch("VT")
      ...> url
      "https://www.weather.gov/xml/current_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations
      iex> alias NOAA.Observations.TemplatesAgent
      iex> template =
      ...>   "https://forecast.weather.gov/xml/past_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> {:error,
      ...>  %{error_code: 404, error_text: "Not Found", state_url: url}} =
      ...>   Observations.fetch("VT")
      iex> url
      "https://forecast.weather.gov/xml/past_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations
      iex> alias NOAA.Observations.TemplatesAgent
      iex> template =
      ...>   "htp://forecast.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> {:error,
      ...>  %{
      ...>    error_code: :nxdomain,
      ...>    error_text: "Non-Existent Domain",
      ...>    state_url: url
      ...>  }} = Observations.fetch("VT")
      iex> url
      "htp://forecast.weather.gov/xml/current_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations
      iex> alias NOAA.Observations.TemplatesAgent
      iex> template = "http://localhost:65535"
      iex> TemplatesAgent.update_state_template(template)
      iex> {:error,
      ...>  %{
      ...>    error_code: :econnrefused,
      ...>    error_text: "Connection Refused By Server",
      ...>    state_url: url
      ...>  }} = Observations.fetch("VT")
      iex> url
      "http://localhost:65535"
  """
  @spec fetch(State.code(), Keyword.t()) :: t | {:error, State.error()}
  def fetch(state_code, options \\ []) do
    case State.stations(state_code) do
      {:ok, stations} ->
        _fetch(stations, state_code, options, @fetches_left)

      {:error, error_code, error_text} ->
        {:error, _error(state_code, error_code, error_text)}
    end
  end

  ## Private functions

  @spec await_timeout :: non_neg_integer
  defp await_timeout, do: get_env(:await_timeout)

  @spec _error(State.code(), any, String.t()) :: State.error()
  defp _error(state_code, error_code, error_text) do
    %{
      state_code: state_code,
      state_name: @state_names[state_code],
      state_url: TemplatesAgent.state_url(state_code: state_code),
      error_code: error_code,
      error_text: error_text
    }
  end

  @spec _fetch([Station.t()], State.code(), keyword, non_neg_integer) ::
          t | no_return
  defp _fetch(_stations, _state_code, _options, _fetches_left = 0) do
    :ok = Log.info(:halting, __ENV__)
    # Ensure message logged before halting...
    :ok = Process.sleep(@wait)
    System.halt()
  end

  defp _fetch(stations, state_code, options, fetches_left) do
    try do
      stations
      |> Enum.map(&Task.async(Station, :observation, [&1, state_code]))
      |> Enum.map(&Task.await(&1, await_timeout()))
      # [{:ok, obs1}, {:ok, obs2}...{:error, err1}, {:error, err2}...] ->
      # %{ok: [obs1, obs2...], error: [err1, err2...]}
      |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)
    catch
      :exit, {:timeout, {Task, :await, [%Task{mfa: mfa}, timeout]}} ->
        left = fetches_left - 1
        {mfa, function} = {inspect(mfa), fun(__ENV__)}
        :ok = Log.error(:timeout, {mfa, timeout, state_code, left, __ENV__})
        :ok = Message.timeout(state_code, left)
        map = %{mfa: mfa, timeout: timeout, function: function}
        :ok = Table.write(@timeout_spec, [map], options)
        _fetch(stations, state_code, options, left)
    end
  end
end
