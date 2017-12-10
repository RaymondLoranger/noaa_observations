# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :elixir, ansi_enabled: true # mix messages in colors

# config :io_ansi_table, async: true # truthy -> cast; falsy -> call
config :io_ansi_table, align_specs: [
  center: "station_id", right: "wind_mph"
]
config :io_ansi_table, headers: [
  "station_id", "weather", "temperature_string", "wind_mph", "location"
]
config :io_ansi_table, header_fixes: %{
  ~r[ id$]i  => " ID",
  ~r[ mph$]i => " MPH"
}
config :io_ansi_table, sort_specs: [
  desc: "temperature_string", asc: "wind_mph"
]
config :io_ansi_table, margins: [
  top:    0, # line(s) before table
  bottom: 0, # line(s) after table
  left:   1  # space(s) left of table
]
# config :io_ansi_table, max_width: 88

config :logger, backends: [
  :console,
  {LoggerFileBackend, :error_log},
  {LoggerFileBackend, :info_log}
]
config :logger, compile_time_purge_level: :info # purges debug messages
config :logger, level: :info # prevents debug messages
config :logger, :console, colors: [
  debug: :light_cyan,
  info:  :light_green,
  warn:  :light_yellow,
  error: :light_red
]
format = "$date $time [$level] $levelpad$message\n"
config :logger, :console, format: format
config :logger, :error_log, format: format
config :logger, :error_log, path: "./log/error.log", level: :error
config :logger, :info_log, format: format
config :logger, :info_log, path: "./log/info.log", level: :info

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
  switch:  :light_yellow,
  value:   :light_magenta
}
config :noaa_observations, strict: [
  help: :boolean, last: :boolean, bell: :boolean, table_style: :string
]
config :noaa_observations, url_templates: [
  state: "http://w1.weather.gov/xml/current_obs/seek.php?state={st}&Find=Find",
  station: "http://w1.weather.gov/xml/current_obs/{stn}.xml"
]

#     import_config "#{Mix.env}.exs"
