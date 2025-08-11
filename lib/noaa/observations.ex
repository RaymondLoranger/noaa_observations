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

  @fetches_max get_env(:fetches_max)

  @typedoc "Groups of station observations/errors/timeouts"
  @type groups :: %{
          optional(:ok) => [Station.observation()],
          optional(:error) => [Station.error()],
          optional(:timeout) => [Station.time_out()]
        }
  @typedoc "Group of station timeouts"
  @type timeout_group :: %{optional(:timeout) => [Station.time_out()]}

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
      iex> template = "http://localhost:65535"
      iex> :ok = TemplatesAgent.update_state_template(template)
      iex> {:error,
      ...>  %{
      ...>    state_code: "VT",
      ...>    state_name: "Vermont",
      ...>    state_url: url,
      ...>    error_code: :econnrefused,
      ...>    error_text: "Connection Refused By Server"
      ...>  }} = Observations.fetch("VT")
      iex> url
      "http://localhost:65535"
  """
  @spec fetch(State.code()) :: groups | {:error, State.error()}
  def fetch(state_code) do
    case State.stations(state_code) do
      {:ok, stations} ->
        _fetch(stations, state_code, %{}, @fetches_max)

      {:error, error_code, error_text} ->
        {:error, _state_error(state_code, error_code, error_text)}
    end
  end

  ## Private functions

  @spec await_timeout :: non_neg_integer
  defp await_timeout, do: get_env(:await_timeout)

  @spec _fetch([Station.t()], State.code(), timeout_group, non_neg_integer) ::
          groups
  defp _fetch(_stations, _state_code, timeout_group, 0) do
    timeout_group
  end

  defp _fetch(stations, state_code, timeout_group, fetches_left) do
    try do
      stations
      |> Enum.map(&Task.async(Station, :observation, [&1, state_code]))
      |> Enum.map(&Task.await(&1, await_timeout()))
      # [{:ok, obs1}, {:ok, obs2}...{:error, err1}, {:error, err2}...] ->
      # %{ok: [obs1, obs2...], error: [err1, err2...]}
      |> Enum.group_by(&key/1, &value/1)
      |> Map.merge(timeout_group)
    catch
      :exit, {:timeout, {Task, :await, [%Task{mfa: mfa}, timeout]}} ->
        fetches_left = fetches_left - 1
        timeout_group = timeout_group(mfa, timeout, fetches_left, __ENV__)
        :ok = Log.warning(:timeout, {timeout_group, state_code, __ENV__})
        _fetch(stations, state_code, timeout_group, fetches_left)
    end
  end

  @spec key({atom, map}) :: atom
  defp key({k, _v}), do: k

  @spec value({atom, map}) :: map
  defp value({_k, v}), do: v

  @spec timeout_group(tuple, timeout, non_neg_integer, Macro.Env.t()) ::
          timeout_group
  defp timeout_group(mfa, timeout, fetches_left, env) do
    timeout = %{
      mfa: inspect(mfa),
      timeout: timeout,
      function: fun(env),
      attempts: @fetches_max - fetches_left,
      attempt_limit: @fetches_max
    }

    %{timeout: [timeout]}
  end

  @spec _state_error(State.code(), State.error_code(), String.t()) ::
          State.error()
  defp _state_error(state_code, error_code, error_text) do
    %{
      state_code: state_code,
      state_name: Message.state_name(state_code),
      state_url: TemplatesAgent.state_url(state_code: state_code),
      error_code: error_code,
      error_text: error_text
    }
  end
end
