# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations do
  @moduledoc """
  Fetches weather observations for a US state/territory code.
  """

  use PersistConfig

  import Task, only: [async: 3, await: 2]

  alias __MODULE__.{Message, State, Station, URL}
  alias IO.ANSI.Table

  @templates get_env(:url_templates)
  @retry_spec get_env(:retry_spec)

  @doc """
  Fetches weather observations for a `state_code`.

  ## Parameters

    - `state_code` - US state/territory code
    - `template`   - URL template

  ## Examples

      iex> alias NOAA.Observations
      iex> %{ok: observations} = Observations.fetch("VT")
      iex> Enum.all?(observations, &is_map/1) and length(observations) > 0
      true

      iex> alias NOAA.Observations
      iex> template =
      ...>   "http://forecast.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> {:fault,
      ...>  %{
      ...>    error_code: 301,
      ...>    error_text: "Moved Permanently",
      ...>    state_url: url
      ...>  }} = Observations.fetch("VT", template)
      iex> url
      "http://forecast.weather.gov/xml/current_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations
      iex> template =
      ...>   "https://www.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> {:fault,
      ...>  %{
      ...>    error_code: 302,
      ...>    error_text: "Found (Moved Temporarily)",
      ...>    state_url: url
      ...>  }} = Observations.fetch("VT", template)
      ...> url
      "https://www.weather.gov/xml/current_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations
      iex> template =
      ...>   "https://forecast.weather.gov/xml/past_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> {:fault,
      ...>  %{error_code: 404, error_text: "Not Found", state_url: url}} =
      ...>   Observations.fetch("VT", template)
      iex> url
      "https://forecast.weather.gov/xml/past_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations
      iex> template =
      ...>   "htp://forecast.weather.gov/xml/current_obs" <>
      ...>     "/seek.php?state=<%=state_code%>&Find=Find"
      iex> {:fault,
      ...>  %{
      ...>    error_code: :nxdomain,
      ...>    error_text: "Non-Existent Domain",
      ...>    state_url: url
      ...>  }} = Observations.fetch("VT", template)
      iex> url
      "htp://forecast.weather.gov/xml/current_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations
      iex> template = "http://localhost:65535"
      iex> {:fault,
      ...>  %{
      ...>    error_code: :econnrefused,
      ...>    error_text: "Connection Refused By Server",
      ...>    state_url: url
      ...>  }} = Observations.fetch("VT", template)
      iex> url
      "http://localhost:65535"
  """
  @spec fetch(State.code(), URL.template(), Keyword.t()) ::
          %{
            optional(:ok) => [Station.observation()],
            optional(:error) => [Station.error()]
          }
          | {:fault, State.fault()}
  def fetch(state_code, template \\ @templates.state, options \\ []) do
    # IO.inspect(state_code, label: "State Code")
    # IO.inspect(template, label: "Template")
    # IO.inspect(options, label: "Options")
    state_url = URL.for_state(state_code, template)

    case State.stations(state_code, template) do
      {:ok, stations} ->
        try do
          stations
          |> Enum.map(&async(Station, :observation, [&1, state_code]))
          |> Enum.map(&await(&1, 500))
          # [{:ok, obs1}, {:ok, obs2}...{:error, error1}, {:error, error2}...] ->
          # %{ok: [obs1, obs2...], error: [error1, error2...]}
          |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        catch
          :exit, {:timeout, {Task, :await, [%Task{mfa: mfa}, timeout]}} ->
            Message.timeout_error(state_code)
            map = %{error: :timeout, mfa: inspect(mfa), timeout: timeout}
            Table.write(@retry_spec, [map], options)
            # IO.puts("reason => #{inspect(reason)}")
            # IO.puts("error => #{inspect(error)}")
            # IO.puts("mfa => #{inspect(mfa)}")
            # IO.puts("timeout ms => #{inspect(timeout)}")
            fetch(state_code, template)
        end

      {:error, error_code, error_text} ->
        {:fault,
         %{
           error_code: error_code,
           error_text: error_text,
           state_url: state_url
         }}
    end
  end
end
