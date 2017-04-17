# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :noaa_observations, key: :value

config :elixir, ansi_enabled: true # mix messages in colors

config :io_ansi_table, headers: [
  # "station_id", "latitude", "weather", "temperature_string", "wind_mph",
  "station_id", "weather", "temperature_string", "wind_mph",
  # "location", "observation_time_rfc822"
  "location"
]
config :io_ansi_table, header_fixes: %{
  ~r[ id$]i       => " ID",
  ~r[ mph$]i      => " MPH",
  ~r[ rfc(\d+)$]i => " RFC-\\1"
}
config :io_ansi_table, key_headers: ["temperature_string", "wind_mph"]
config :io_ansi_table, margins: [
  top:    0, # line(s) before table
  bottom: 0, # line(s) after table
  left:   1  # space(s) left of table
]
config :io_ansi_table, max_width: 88

config :logger, backends: [
  :console, {LoggerFileBackend, :error}, {LoggerFileBackend, :info}
]
config :logger, compile_time_purge_level: :info # purges debug messages
config :logger, :console,
  colors: [debug: :light_cyan, warn: :light_yellow, error: :light_red]
config :logger, :error, path: "./log/error.log", level: :error
config :logger, :info, path: "./log/info.log", level: :info

config :noaa_observations, aliases: [
  h: :help, l: :last, b: :bell, t: :table_style
]
config :noaa_observations, default_count: 13
config :noaa_observations, default_switches: [
  help: false, last: false, bell: false, table_style: "dark"
]
config :noaa_observations, help_attrs: %{
  arg:     :light_cyan,
  command: :light_yellow,
  normal:  :reset,
  section: :light_green,
  switch:  :light_black,
  value:   :light_magenta
}
config :noaa_observations, strict: [
  help: :boolean, last: :boolean, bell: :boolean, table_style: :string
]
config :noaa_observations, url_templates: %{
  state: "http://w1.weather.gov/xml/current_obs/" <>
    "seek.php?state={st}&Find=Find",
  station: "http://w1.weather.gov/xml/current_obs/{stn}.xml"
}

#
# And access this configuration in your application as:
#
#     Application.get_env(:noaa_observations, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
