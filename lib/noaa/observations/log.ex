defmodule NOAA.Observations.Log do
  use File.Only.Logger
  use PersistConfig

  @state_dict get_env(:state_dict)

  error :fetching, {text, state, env} do
    """
    \nError fetching the weather observations of a state...
    • Error: #{text}
    • State: #{state}
    • Name: #{@state_dict[state] || "?"}
    #{from(env, __MODULE__)}
    """
  end

  info :printing, {state, env} do
    """
    \nPrinting the weather observations of a state...
    • State: #{state}
    • Name: #{@state_dict[state] || "?"}
    #{from(env, __MODULE__)}
    """
  end

  info :fetching_stations, {state, url, env} do
    """
    \nFetching the stations of a state...
    • URL: #{url}
    • State: #{state}
    • Name: #{@state_dict[state] || "?"}
    #{from(env, __MODULE__)}
    """
  end

  info :fetching_observation, {station, name, url, env} do
    """
    \nFetching the latest observation of a station...
    • URL: #{url}
    • Station: #{station}
    • Name: #{name}
    #{from(env, __MODULE__)}
    """
  end

  info :fetching_observations, {state, env} do
    """
    \nFetching the weather observations of a state...
    • State: #{state}
    • Name: #{@state_dict[state] || "?"}
    #{from(env, __MODULE__)}
    """
  end
end
