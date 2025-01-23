defmodule NOAA.Observations.Message do
  use PersistConfig

  alias NOAA.Observations.State

  @state_names get_env(:state_names)
  @observations_spec get_env(:observations_spec)
  @stations_spec get_env(:stations_spec)
  @state_spec get_env(:state_spec)
  @timeout_spec get_env(:timeout_spec)

  @spec status(pos_integer) :: String.t()
  def status(301), do: "Moved Permanently"
  def status(302), do: "Found (Moved Temporarily)"
  def status(304), do: "Not Modified"
  def status(305), do: "Use Proxy"
  def status(306), do: "Switch Proxy"
  def status(307), do: "Temporary Redirect"
  def status(308), do: "Permanent Redirect"
  def status(403), do: "Forbidden"
  def status(404), do: "Not Found"
  def status(408), do: "Request Timeout"
  def status(500), do: "Internal Server Error"
  def status(501), do: "Not Implemented"
  def status(502), do: "Bad Gateway"
  def status(503), do: "Service Unavailable"
  def status(504), do: "Gateway Timeout"
  def status(code), do: "Status code #{code}"

  @spec error(term) :: String.t()
  def error(:nxdomain), do: "Non-Existent Domain"
  def error(:econnrefused), do: "Connection Refused By Server"
  def error(:checkout_failure), do: "Checkout Failure"
  def error(:servfail), do: "Server Failure"
  def error(:refused), do: "Query Refused"
  def error(:formerror), do: "Format Error"
  def error(reason), do: "Reason => #{inspect(reason)}"

  @spec writing_table(:ok | :error, State.code()) :: :ok
  def writing_table(:ok, code) do
    [
      @observations_spec.left_margin,
      [:white, "Writing table of weather observations for "],
      [:light_white, "#{@state_names[code] || "???"}"],
      [:white, "..."]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  def writing_table(:error, code) do
    [
      @stations_spec.left_margin,
      [:white, "Writing table of unresponsive stations for "],
      [:light_white, "#{@state_names[code] || "???"}"],
      [:white, "..."]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  @spec stations_not_fetched(State.code()) :: :ok
  def stations_not_fetched(code) do
    [
      @state_spec.left_margin,
      [:white, "Failed to fetch the stations of "],
      [:light_white, "#{@state_names[code] || "???"}"],
      [:white, "..."]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  @spec timeout(State.code(), non_neg_integer) :: :ok
  def timeout(state_code, retries) do
    [
      @timeout_spec.left_margin,
      [:white, "Timeout while fetching observations for "],
      [:light_white, "#{@state_names[state_code] || "???"}"],
      [:white, "...#{if retries > 0, do: " Trying again...", else: ""}"]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end
end
