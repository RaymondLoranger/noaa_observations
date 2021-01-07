defmodule NOAA.Observations.Log do
  use File.Only.Logger
  use PersistConfig

  @state_dict get_env(:state_dict)

  error :fetching, {text, state} do
    """
    \nError fetching the weather observations of a state...
    • Error: #{text}
    • State: #{state}
    • Name: #{@state_dict[state] || "?"}
    #{from()}
    """
  end

  info :printing, {state, env} do
    """
    \nPrinting the weather observations of a state...
    • Inside function:
      #{fun(env)}
    • State: #{state}
    • Name: #{@state_dict[state] || "?"}
    #{from()}
    """
  end

  info :fetching_stations, {state, url, env} do
    """
    \nFetching the stations of a state...
    • Inside function:
      #{fun(env)}
    • URL: #{url}
    • State: #{state}
    • Name: #{@state_dict[state] || "?"}
    #{from()}
    """
  end

  info :fetching_observation, {station, name, url, env} do
    """
    \nFetching the latest observation of a station...
    • Inside function:
      #{fun(env)}
    • URL: #{url}
    • Station: #{station}
    • Name: #{name}
    #{from()}
    """
  end

  info :fetching_observations, {state, env} do
    """
    \nFetching the weather observations of a state...
    • Inside function:
      #{fun(env)}
    • State: #{state}
    • Name: #{@state_dict[state] || "?"}
    #{from()}
    """
  end
end
