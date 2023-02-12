defmodule NOAA.Observations.Log do
  use File.Only.Logger
  use PersistConfig

  @state_names get_env(:state_names)

  error :fetching_error, {code, text, env} do
    """
    \nError fetching weather observations of a state...
    • Error: #{text}
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
    #{from(env, __MODULE__)}
    """
  end

  info :writing_table, {code, env} do
    """
    \nWriting table of weather observations for a state...
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
    #{from(env, __MODULE__)}
    """
  end

  info :fetching_stations, {code, url, env} do
    """
    \nFetching the stations of a state...
    • URL: #{url}
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
    #{from(env, __MODULE__)}
    """
  end

  info :fetching_observation, {id, name, code, url, env} do
    """
    \nFetching the latest observation of a station...
    • URL: #{url}
    • Station: #{id}
    • Station name: #{maybe_break(name, 16)}
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
    #{from(env, __MODULE__)}
    """
  end

  info :fetching_observations, {code, env} do
    """
    \nFetching the weather observations of a state...
    • State: #{code}
    • State name: #{@state_names[code] || "???"}
    #{from(env, __MODULE__)}
    """
  end
end
