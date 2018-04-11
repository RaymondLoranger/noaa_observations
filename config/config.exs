# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Mix messages in colors...
config :elixir, ansi_enabled: true

# If truthy -> GenServer.cast, otherwise -> GenServer.call...
# config :io_ansi_table, async: true

config :io_ansi_table,
  align_specs: [
    # center: "station_id",
    right: "wind_mph"
  ]

config :io_ansi_table,
  headers: [
    # "station_id",
    "weather",
    "temperature_string",
    "wind_mph",
    "location"
  ]

config :io_ansi_table,
  header_fixes: %{
    # ~r[ id$]i => " ID",
    ~r[ mph$]i => " MPH"
  }

config :io_ansi_table,
  sort_specs: [
    desc: "temperature_string",
    asc: "wind_mph"
  ]

config :io_ansi_table,
  margins: [
    # Line(s) before table...
    top: 0,
    # Line(s) after table...
    bottom: 0,
    # Space(s) left of table...
    left: 1
  ]

# config :io_ansi_table, max_width: 88

config :logger,
  backends: [
    :console,
    {LoggerFileBackend, :error_log},
    {LoggerFileBackend, :info_log}
  ]

# Purges debug messages...
config :logger, compile_time_purge_level: :info

# Prevents debug messages...
config :logger, level: :info

config :logger, :console,
  colors: [
    debug: :light_cyan,
    info: :light_green,
    warn: :light_yellow,
    error: :light_red
  ]

format = "$date $time [$level] $levelpad$message\n"

config :logger, :console, format: format

config :logger, :error_log, format: format
config :logger, :error_log, path: "./log/error.log", level: :error

config :logger, :info_log, format: format
config :logger, :info_log, path: "./log/info.log", level: :info

config :noaa_observations, default_count: 13

#     import_config "#{Mix.env}.exs"
import_config "persist.exs"
import_config "persist_book_ref.exs"
