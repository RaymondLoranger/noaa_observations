import Config

scheme = "https"
host = "forecast.weather.gov"
state_path = "/xml/current_obs/seek.php"
station_path = "/xml/current_obs/display.php"
state_query = "state=<%=state_code%>&Find=Find"
station_query = "stid=<%=station_id%>"

config :noaa_observations,
  url_templates: %{
    state: "#{scheme}://#{host}#{state_path}?#{state_query}",
    station: "#{scheme}://#{host}#{station_path}?#{station_query}"
  }
