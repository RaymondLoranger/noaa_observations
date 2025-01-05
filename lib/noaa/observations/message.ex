defmodule NOAA.Observations.Message do
  use PersistConfig

  alias NOAA.Observations.State

  @state_names get_env(:state_names)
  @table_spec get_env(:table_spec)
  @error_spec get_env(:error_spec)
  @fault_spec get_env(:fault_spec)
  @retry_spec get_env(:fault_spec)

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
      @table_spec.left_margin,
      [:white, "Writing table of weather observations for "],
      [:light_white, "#{@state_names[code] || "???"}..."]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  def writing_table(:error, code) do
    [
      @error_spec.left_margin,
      [:white, "Writing table of unresponsive stations for "],
      [:light_white, "#{@state_names[code] || "???"}..."]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  # @spec fetching_error(State.code(), Station.id(), String.t()) :: :ok
  # def fetching_error(code, id, text) do
  #   [
  #     [:white, "Error fetching weather observations of "],
  #     [:light_white, "#{@state_names[code] || "???"} "],
  #     [:white, "for station "],
  #     [:light_white, "#{id}..."],
  #     [:light_yellow, :string.titlecase(text)]
  #   ]
  #   |> IO.ANSI.format()
  #   |> IO.puts()
  # end

  @spec fetching_error(State.code()) :: :ok
  def fetching_error(code) do
    [
      @fault_spec.left_margin,
      [:white, "Error while fetching list of stations for "],
      [:light_white, "#{@state_names[code] || "???"}..."]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  @spec timeout_error(State.code()) :: :ok
  def timeout_error(code) do
    [
      @retry_spec.left_margin,
      [:white, "Error while fetching observations for "],
      [:light_white, "#{@state_names[code] || "???"}"],
      [:white, "... Trying again..."]
    ]
    |> IO.ANSI.format()
    |> IO.puts()
  end
end
