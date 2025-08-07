defmodule NOAA.Observations.Log do
  use File.Only.Logger
  use PersistConfig

  @state_names get_env(:state_names)

  info :writing_table, {:ok, state_code, env} do
    """
    \nWriting table of weather observations for a state...
    • State: #{state_code}
    • State name: #{@state_names[state_code] || "???"}
    #{from(env, __MODULE__)}\
    """
  end

  info :writing_table, {:error, state_code, env} do
    """
    \nWriting table of unresponsive stations for a state...
    • State: #{state_code}
    • State name: #{@state_names[state_code] || "???"}
    #{from(env, __MODULE__)}\
    """
  end

  info :stations_fetched, {state_code, state_url, env} do
    """
    \nFetched the stations of a state...
    • URL: #{maybe_break(state_url, 7)}
    • State: #{state_code}
    • State name: #{@state_names[state_code] || "???"}
    #{from(env, __MODULE__)}\
    """
  end

  error :stations_not_fetched,
        {{state_code, state_url, env}, {error_code, error_text}} do
    """
    \nFailed to fetch the stations of a state...
    • URL: #{maybe_break(state_url, 7)}
    • State: #{state_code}
    • State name: #{@state_names[state_code] || "???"}
    • Error code: #{inspect(error_code)}
    • Error: #{maybe_break(error_text, 9)}
    #{from(env, __MODULE__)}\
    """
  end

  info :observation_fetched,
       {station_id, station_name, station_url, state_code, env} do
    """
    \nFetched the latest observation of a station...
    • URL: #{maybe_break(station_url, 7)}
    • Station: #{station_id}
    • Station name: #{maybe_break(station_name, 16)}
    • State: #{state_code}
    • State name: #{@state_names[state_code] || "???"}
    #{from(env, __MODULE__)}\
    """
  end

  error :observation_not_fetched,
        {{station_id, station_name, station_url, state_code, env},
         {error_code, error_text}} do
    """
    \nFailed to fetch the latest observation of a station...
    • URL: #{maybe_break(station_url, 7)}
    • Station: #{station_id}
    • Station name: #{maybe_break(station_name, 16)}
    • State: #{state_code}
    • State name: #{@state_names[state_code] || "???"}
    • Error code: #{inspect(error_code)}
    • Error: #{maybe_break(error_text, 9)}
    #{from(env, __MODULE__)}\
    """
  end

  error :timeout, {mfa, timeout, state_code, retries, env} do
    """
    \nTimeout while fetching observations for a state...
    • State: #{state_code}
    • State name: #{@state_names[state_code] || "???"}
    • MFA: #{maybe_break(mfa, 7)}
    • Timeout: #{timeout} ms
    • Retries left: #{retries}
    #{from(env, __MODULE__)}\
    """
  end

  info :halting, env do
    """
    \nHalting the Erlang runtime system...
    #{from(env, __MODULE__)}\
    """
  end
end
