import Config

alias IO.ANSI.Table.Spec

headers = ["weather", "temperature_string", "wind_mph", "location"]

options = [
  align_specs: [right: "wind_mph"],
  header_fixes: %{~r[ mph$]i => " MPH"},
  sort_specs: [desc: "temperature_string", asc: "wind_mph"],
  margins: [top: 0, bottom: 0, left: 1]
]

config :noaa_observations,
  table_spec: Spec.new(headers, options) |> Spec.develop()
