defmodule NOAA.Observations.TableWriter do
  @moduledoc """
  Prints a table of weather observations from the NOAA Weather Service.

  May also print error tables (state error or station errors/timeout).
  """

  use PersistConfig

  alias IO.ANSI.Table
  alias NOAA.Observations
  alias NOAA.Observations.{Log, Message, State}

  @observations_spec get_env(:observations_spec)
  @state_error_spec get_env(:state_error_spec)
  @stations_spec get_env(:stations_spec)
  @timeout_spec get_env(:timeout_spec)

  @type groups :: Observations.groups()

  @spec write_table({:error, State.error()}, State.code(), keyword) :: :ok
  def write_table({:error, state_error}, state_code, options) do
    :ok = write_state_error_table(state_error, state_code, options)
  end

  @spec write_table(groups, State.code(), keyword) :: :ok
  def write_table(groups, state_code, options) do
    :ok = write_timeout_table(groups, state_code, options)
    :ok = write_stations_table(groups, state_code, adjust(options))
    :ok = write_observations_table(groups, state_code, options)
  end

  ## Private functions

  @dialyzer {:nowarn_function, [write_state_error_table: 3]}
  @spec write_state_error_table(State.error(), State.code(), keyword) :: :ok
  defp write_state_error_table(state_error, state_code, options) do
    :ok = Log.info(:writing_state_error_table, {state_error, __ENV__})
    :ok = Message.writing_state_error_table(state_code)
    :ok = Table.write(@state_error_spec, [state_error], options)
  end

  @dialyzer {:nowarn_function, [write_observations_table: 3]}
  @spec write_observations_table(groups, State.code(), keyword) :: :ok
  defp write_observations_table(%{ok: observations}, state_code, options) do
    :ok = Log.info(:writing_observations_table, {state_code, __ENV__})
    :ok = Message.writing_observations_table(state_code)
    :ok = Table.write(@observations_spec, observations, options)
  end

  defp write_observations_table(%{timeout: _}, _state_code, _options) do
    :ok
  end

  defp write_observations_table(_groups, state_code, options) do
    :ok = write_observations_table(%{ok: []}, state_code, options)
  end

  @dialyzer {:nowarn_function, [write_stations_table: 3]}
  @spec write_stations_table(groups, State.code(), keyword) :: :ok
  defp write_stations_table(%{error: station_errors}, state_code, options) do
    :ok = Log.info(:writing_stations_table, {state_code, __ENV__})
    :ok = Message.writing_stations_table(state_code)
    :ok = Table.write(@stations_spec, station_errors, options)
  end

  defp write_stations_table(_groups, _options, _state_code) do
    :ok
  end

  @spec write_timeout_table(groups, State.code(), keyword) :: :ok
  defp write_timeout_table(%{timeout: timeouts}, state_code, options) do
    :ok = Log.info(:writing_timeout_table, {state_code, __ENV__})
    :ok = Message.writing_timeout_table(state_code)
    :ok = Table.write(@timeout_spec, timeouts, options)
  end

  defp write_timeout_table(_groups, _options, _state_code) do
    :ok
  end

  @spec adjust(keyword) :: keyword
  defp adjust(options), do: put_in(options[:count], 999)
end
