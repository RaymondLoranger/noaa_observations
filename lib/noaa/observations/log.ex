defmodule NOAA.Observations.Log do
  use File.Only.Logger

  alias NOAA.Observations.Message

  info :writing_observations_table, {state_code, env} do
    """
    \nWriting table of weather observations for a state...
    • State: #{state_code}
    • State name: #{Message.state_name(state_code)}
    #{from(env, __MODULE__)}\
    """
  end

  info :writing_state_error_table,
       {%{
          state_code: state_code,
          state_name: state_name,
          state_url: state_url,
          error_code: error_code,
          error_text: error_text
        } = _state_error, env} do
    """
    \nWriting table of unresponsive state...
    • State: #{state_code}
    • State name: #{state_name}
    • Error code: #{inspect(error_code)}
    • Error: #{maybe_break(error_text, 9)}
    • URL: #{maybe_break(state_url, 7)}
    #{from(env, __MODULE__)}\
    """
  end

  info :writing_stations_table, {state_code, env} do
    """
    \nWriting table of unresponsive stations for a state...
    • State: #{state_code}
    • State name: #{Message.state_name(state_code)}
    #{from(env, __MODULE__)}\
    """
  end

  info :writing_timeout_table, {state_code, env} do
    """
    \nWriting table of fetch timeouts for a state...
    • State: #{state_code}
    • State name: #{Message.state_name(state_code)}
    #{from(env, __MODULE__)}\
    """
  end

  info :stations_fetched, {state_code, state_url, env} do
    """
    \nFetched the stations of a state...
    • State: #{state_code}
    • State name: #{Message.state_name(state_code)}
    • URL: #{maybe_break(state_url, 7)}
    #{from(env, __MODULE__)}\
    """
  end

  error :stations_not_fetched,
        {{state_code, state_url, env}, error_code, error_text} do
    """
    \nFailed to fetch the stations of a state...
    • State: #{state_code}
    • State name: #{Message.state_name(state_code)}
    • Error code: #{inspect(error_code)}
    • Error: #{maybe_break(error_text, 9)}
    • URL: #{maybe_break(state_url, 7)}
    #{from(env, __MODULE__)}\
    """
  end

  info :observation_fetched,
       {station_id, station_name, station_url, state_code, env} do
    """
    \nFetched the latest observation of a station...
    • Station: #{station_id}
    • Station name: #{maybe_break(station_name, 16)}
    • State: #{state_code}
    • State name: #{Message.state_name(state_code)}
    • URL: #{maybe_break(station_url, 7)}
    #{from(env, __MODULE__)}\
    """
  end

  warning :observation_not_fetched,
          {{station_id, station_name, station_url, state_code, env},
           {error_code, error_text}} do
    """
    \nFailed to fetch the latest observation of a station...
    • Station: #{station_id}
    • Station name: #{maybe_break(station_name, 16)}
    • State: #{state_code}
    • State name: #{Message.state_name(state_code)}
    • Error code: #{inspect(error_code)}
    • Error: #{maybe_break(error_text, 9)}
    • URL: #{maybe_break(station_url, 7)}
    #{from(env, __MODULE__)}\
    """
  end

  warning :timeout,
          {%{
             timeout: [
               %{
                 mfa: mfa,
                 timeout: timeout,
                 function: _function,
                 attempts: attempts,
                 attempt_limit: attempt_limit
               }
             ]
           } = _time_group, state_code, env} do
    """
    \nTimeout while fetching observations for a state...
    • State: #{state_code}
    • State name: #{Message.state_name(state_code)}
    • MFA: #{maybe_break(mfa, 7)}
    • Timeout: #{timeout} ms
    • Attempt number: #{attempts}
    • Attempt limit: #{attempt_limit}
    #{from(env, __MODULE__)}\
    """
  end
end
