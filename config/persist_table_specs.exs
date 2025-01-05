import Config

alias IO.ANSI.Table.Spec

headers = ~W[
  weather temperature_string wind_mph wind_dir visibility_mi station_id location
]

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
  table_spec: Spec.new(headers, options) |> Spec.develop()

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
  error_spec: Spec.new(headers, options) |> Spec.develop()

headers = ~W[error_code error_text state_url]a

options = [
  # align_specs: [left: :station_id],
  header_fixes: %{
    "Error Code" => "Code",
    "Error Text" => "Error",
    "State Url" => "URL"
  },
  margins: [top: 0, bottom: 0, left: 1]
]

config :noaa_observations,
  fault_spec: Spec.new(headers, options) |> Spec.develop()

headers = ~W[error timeout mfa]a

options = [
  align_specs: [right: :timeout],
  header_fixes: %{
    "Mfa" => "MFA",
    "Timeout" => "Timeout ms"
  },
  margins: [top: 0, bottom: 0, left: 1]
]

config :noaa_observations,
  retry_spec: Spec.new(headers, options) |> Spec.develop()
