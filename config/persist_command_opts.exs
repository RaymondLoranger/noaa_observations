import Config

config :noaa_observations, default_count: "22"

config :noaa_observations,
  default_switches: %{
    help: false,
    bell: false,
    last: false,
    table_style: "dark"
  }

config :noaa_observations,
  parsing_options: [
    strict: [
      help: :boolean,
      bell: :boolean,
      last: :boolean,
      table_style: :string
    ],
    aliases: [h: :help, b: :bell, l: :last, t: :table_style]
  ]
