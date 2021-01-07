import Config

config :noaa_observations,
  url_templates: [
    state:
      "https://w1.weather.gov/xml/current_obs/seek.php?state=" <>
        "<%=state%>&Find=Find",
    station:
      "https://w1.weather.gov/xml/current_obs/display.php?stid=" <>
        "<%=station%>"
  ]
