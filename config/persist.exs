use Mix.Config

config :noaa_observations,
  aliases: [
    h: :help,
    l: :last,
    b: :bell,
    t: :table_style
  ]

config :noaa_observations,
  default_switches: [
    help: false,
    last: false,
    bell: false,
    table_style: "dark"
  ]

config :noaa_observations,
  help_attrs: %{
    arg: :light_cyan,
    command: :light_yellow,
    normal: :reset,
    section: :light_green,
    switch: :light_yellow,
    value: :light_magenta
  }

config :noaa_observations,
  strict: [
    help: :boolean,
    last: :boolean,
    bell: :boolean,
    table_style: :string
  ]

config :noaa_observations,
  url_templates: [
    state:
      "http://w1.weather.gov/" <>
        "xml/current_obs/seek.php?state={st}&Find=Find",
    station: "http://w1.weather.gov/xml/current_obs/{stn}.xml"
  ]
