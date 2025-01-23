# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations do
  @moduledoc """
  Fetches weather observations for a US state/territory code.
  """

  use PersistConfig
  use File.Only.Logger

  alias __MODULE__.{Log, Message, RetriesAgent, State, Station, TemplatesAgent}
  alias IO.ANSI.Table

  @state_names get_env(:state_names)
  @timeout_spec get_env(:timeout_spec)
  @wait 300

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
  @spec fetch(State.code(), Keyword.t()) ::
          %{
            optional(:ok) => [Station.observation()],
            optional(:error) => [Station.error()]
          }
          | {:error, State.error()}
  def fetch(state_code, options \\ []) do
    state_url = TemplatesAgent.state_url(state_code: state_code)

    case State.stations(state_code) do
      {:ok, stations} ->
        try do
          stations
          |> Enum.map(&Task.async(Station, :observation, [&1, state_code]))
          # Default timeout is 5000 ms...
          |> Enum.map(&Task.await/1)
          # [{:ok, obs1}, {:ok, obs2}...{:error, err1}, {:error, err2}...] ->
          # %{ok: [obs1, obs2...], error: [err1, err2...]}
          |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        catch
          :exit, {:timeout, {Task, :await, [%Task{mfa: mfa}, timeout]}} ->
            {mfa, function} = {inspect(mfa), fun(__ENV__)}
            retries = RetriesAgent.get_and_decrement()

            :ok =
              Log.error(:timeout, {mfa, timeout, state_code, retries, __ENV__})

            :ok = Message.timeout(state_code, retries)
            map = %{mfa: mfa, timeout: timeout, function: function}
            Table.write(@timeout_spec, [map], options)

            if retries > 0 do
              fetch(state_code, options)
            else
              :ok = Log.info(:halting, {__ENV__})
              # Ensure messages logged before exiting...
              Process.sleep(@wait)
              System.halt()
            end
        end

      {:error, error_code, error_text} ->
        {:error,
         %{
           state_code: state_code,
           state_name: @state_names[state_code],
           error_code: error_code,
           error_text: error_text,
           state_url: state_url
         }}
    end
  end
end
