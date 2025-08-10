# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations do
  @moduledoc """
  Fetches weather observations of a US state/territory.
  """

  use File.Only.Logger
  use PersistConfig

  alias __MODULE__.{Log, Message, State, Station, TemplatesAgent}
  alias IO.ANSI.Table

  @fetches_left get_env(:fetches_left)
  @timeout_spec get_env(:timeout_spec)
  @wait 500

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
      iex> :ok = TemplatesAgent.reset()
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
      iex> {:error, %{error_code: 404, error_text: text, state_url: url}} =
      ...>   Observations.fetch("VT")
      iex> {url, text}
      {"https://forecast.weather.gov/xml/past_obs/seek.php?state=VT&Find=Find",
       "Not Found"}

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
  @spec fetch(State.code(), keyword) :: t | {:error, State.error()}
  def fetch(state_code, options \\ []) do
    case State.stations(state_code) do
      {:ok, stations} ->
        _fetch(stations, state_code, options, @fetches_left)

      {:error, error_code, error_text} ->
        {:error, _state_error(state_code, error_code, error_text)}
    end
  end

  ## Private functions

  @spec await_timeout :: non_neg_integer
  defp await_timeout, do: get_env(:await_timeout)

  # TODO: the map should be minimalist...
  # only state_code and error_code are needed
  @spec _state_error(State.code(), any, String.t()) :: State.error()
  defp _state_error(state_code, error_code, error_text) do
    %{
      state_code: state_code,
      state_name: Message.state_name(state_code),
      state_url: TemplatesAgent.state_url(state_code: state_code),
      error_code: error_code,
      error_text: error_text
    }
  end

  @spec _fetch([Station.t()], State.code(), keyword, non_neg_integer) ::
          t | no_return
  defp _fetch(_stations, _state_code, _options, _fetches_left = 0) do
    :ok = Log.error(:halting, __ENV__)
    # Ensure message logged before halting...
    :ok = Process.sleep(@wait)
    System.halt()
  end

  # TODO: argument options has no business here...
  # return some struct so as to print timeout table in CLI
  # %{ok: [obs1, obs2...], error: [err1, err2...], timeout: [to1, to2...]}
  # Map.merge(ok_and_err_map, timeout_map)
  # Writing table of fetch timeout for Texas... Trying again...
  # ┌──────────────────────────────────────────────┬────────────┬
  # │ MFA {module, function, arity}                │ Timeout ms │
  # ├──────────────────────────────────────────────┼────────────┼
  # │ {NOAA.Observations.Station, :observation, 2} │        111 │
  # └──────────────────────────────────────────────┴────────────┴
  #
  # ┬────────────────────────────┬───────────
  # │ Function                   │ Attempts    Attempt limit
  # ┼────────────────────────────┼───────────
  # │ NOAA.Observations._fetch/4 │        4                5
  # ┴────────────────────────────┴───────────
  #
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
        fetches_left = fetches_left - 1
        {mfa, function} = {inspect(mfa), fun(__ENV__)}
        timeout_error = %{mfa: mfa, timeout: timeout, function: function}
        args = {timeout_error, {state_code, fetches_left, __ENV__}}
        :ok = Log.warning(:writing_timeout_table, args)
        :ok = Message.writing_timeout_table(state_code, fetches_left)
        :ok = Table.write(@timeout_spec, [timeout_error], options)
        _fetch(stations, state_code, options, fetches_left)
    end
  end
end
