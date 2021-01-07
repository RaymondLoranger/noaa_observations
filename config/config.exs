import Config

config :elixir, ansi_enabled: true
import_config "config_logger.exs"
import_config "#{Mix.env()}.exs"
