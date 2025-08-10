import Config

alias IO.ANSI.Table.Spec

# ┌─────────────────────────────────┐
# │ ••• Observations table spec ••• │
# └─────────────────────────────────┘

headers = ~W[
  weather temperature_string wind_mph wind_dir visibility_mi station_id location
]

headers =
  case Mix.env() do
    :dev -> headers
    :prod -> headers -- ~W[station_id]
    :test -> headers -- ~W[visibility_mi]
  end

options = [
  align_specs: [right: "wind_mph", right: "visibility_mi"],
  header_fixes: %{
    ~r[ mph$]i => " MPH",
    "Temperature String" => "Temperature",
    "Visibility Mi" => "Vis mi",
    "Station Id" => "Stn"
  },
  sort_specs: [desc: "temperature_string", asc: "wind_mph"],
  margins: [top: 0, bottom: 0, left: 1]
]

config :noaa_observations,
  observations_spec: Spec.new(headers, options) |> Spec.develop()

# ┌───────────────────────────────────┐
# │ ••• Station errors table spec ••• │
# └───────────────────────────────────┘

headers = ~W[station_id station_name error_code error_text station_url]a

options = [
  # align_specs: [left: :station_id],
  header_fixes: %{
    "Station Id" => "Stn",
    "Error Code" => "Code",
    "Error Text" => "Error",
    "Station Url" => "URL"
  },
  sort_specs: [asc: :station_id],
  margins: [top: 0, bottom: 0, left: 1]
]

config :noaa_observations,
  stations_spec: Spec.new(headers, options) |> Spec.develop()

# ┌────────────────────────────────┐
# │ ••• State error table spec ••• │
# └────────────────────────────────┘

headers = ~W[state_code state_name error_code error_text state_url]a

options = [
  # align_specs: [left: :station_id],
  header_fixes: %{
    "State Code" => "St",
    "Error Code" => "Code",
    "Error Text" => "Error",
    "State Url" => "URL"
  },
  margins: [top: 0, bottom: 0, left: 1]
]

config :noaa_observations,
  state_error_spec: Spec.new(headers, options) |> Spec.develop()

# ┌────────────────────────────┐
# │ ••• Timeout table spec ••• │
# └────────────────────────────┘

headers = ~W[mfa timeout function]a

options = [
  align_specs: [right: :timeout],
  header_fixes: %{
    "Mfa" => "MFA {module, function, arity}",
    "Timeout" => "Timeout ms"
  },
  margins: [top: 0, bottom: 0, left: 1]
]

config :noaa_observations,
  timeout_spec: Spec.new(headers, options) |> Spec.develop()
