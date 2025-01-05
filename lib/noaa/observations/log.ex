defmodule NOAA.Observations.Log do
  use File.Only.Logger
  use PersistConfig

  @state_names get_env(:state_names)

  info :writing_table, {:ok, code, env} do
    """
    \nWriting table of weather observations for a state...
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
    #{from(env, __MODULE__)}\
    """
  end

  info :writing_table, {:error, code, env} do
    """
    \nWriting table of erroneous stations for a state...
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
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
        {state_code, state_url, error_code, error, env} do
    """
    \nFailed to fetch the stations of a state...
    • URL: #{maybe_break(state_url, 7)}
    • State: #{state_code}
    • State name: #{@state_names[state_code] || "???"}
    • Error code: #{inspect(error_code)}
    • Error: #{maybe_break(error, 9)}
    #{from(env, __MODULE__)}\
    """
  end

  info :observation_fetched, {id, name, code, url, env} do
    """
    \nFetched the latest observation of a station...
    • URL: #{maybe_break(url, 7)}
    • Station: #{id}
    • Station name: #{maybe_break(name, 16)}
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
    #{from(env, __MODULE__)}\
    """
  end

  error :observation_not_fetched,
        {id, name, code, error_code, error, url, env} do
    """
    \nFailed to fetch the latest observation of a station...
    • URL: #{maybe_break(url, 7)}
    • Station: #{id}
    • Station name: #{maybe_break(name, 16)}
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
    • Error code: #{inspect(error_code)}
    • Error: #{maybe_break(error, 9)}
    #{from(env, __MODULE__)}\
    """
  end
end
