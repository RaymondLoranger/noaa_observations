import Config

config :noaa_observations,
       :await_timeout,
       System.get_env("AWAIT_TIMEOUT", "5000") |> String.to_integer()
