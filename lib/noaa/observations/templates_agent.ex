defmodule NOAA.Observations.TemplatesAgent do
  @moduledoc """
  An agent process loading state and station URL templates from a config file.
  """

  use Agent
  use PersistConfig

  alias __MODULE__

  @typedoc "URL"
  @type url :: String.t()
  @typedoc "URL template"
  @type template :: String.t()

  @templates get_env(:url_templates)

  @doc """
  Spawns an agent process that loads URL templates from a config file.

  ## Examples

      iex> alias NOAA.Observations.TemplatesAgent
      iex> {:error, {:already_started, agent}} = TemplatesAgent.start_link(:ok)
      iex> is_pid(agent) and agent == Process.whereis(TemplatesAgent)
      true
  """
  @spec start_link(term) :: Agent.on_start()
  def start_link(_arg = :ok) do
    Agent.start_link(&templates/0, name: TemplatesAgent)
  end

  @doc """
  Returns a state URL based on `binding` and the state of the templates agent.

  ## Examples

      iex> alias NOAA.Observations.TemplatesAgent
      iex> TemplatesAgent.refresh()
      iex> TemplatesAgent.state_url(state_code: "VT")
      "https://forecast.weather.gov/xml/current_obs/seek.php?state=VT&Find=Find"

      iex> alias NOAA.Observations.TemplatesAgent
      iex> template = "http://noaa.gov/seek.php?state=<%=state_abbr%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> TemplatesAgent.state_url(state_abbr: "NY")
      "http://noaa.gov/seek.php?state=NY&Find=Find"
  """
  @spec state_url(keyword) :: url
  def state_url(binding) when is_list(binding) do
    TemplatesAgent |> Agent.get(& &1.state) |> EEx.eval_string(binding)
  end

  @doc """
  Returns a station URL based on `binding` and the state of the templates agent.

  ## Examples

      iex> alias NOAA.Observations.TemplatesAgent
      iex> TemplatesAgent.refresh()
      iex> TemplatesAgent.station_url(station_id: "KFSO")
      "https://forecast.weather.gov/xml/current_obs/display.php?stid=KFSO"

      iex> alias NOAA.Observations.TemplatesAgent
      iex> template = "http://noaa.gov/display.php?stid=<%=stn_id%>"
      iex> TemplatesAgent.update_station_template(template)
      iex> TemplatesAgent.station_url(stn_id: "KBTV")
      "http://noaa.gov/display.php?stid=KBTV"
  """
  @spec station_url(keyword) :: url
  def station_url(binding) when is_list(binding) do
    TemplatesAgent |> Agent.get(& &1.station) |> EEx.eval_string(binding)
  end

  @doc """
  Updates the state URL template in the templates agent.

  ## Examples

      iex> alias NOAA.Observations.TemplatesAgent
      iex> template = "http://noaa.gov/seek.php?state=<%=state_code%>&Find=Find"
      iex> TemplatesAgent.update_state_template(template)
      iex> Agent.get(TemplatesAgent, & &1.state) == template
      true
  """
  @spec update_state_template(template) :: :ok
  def update_state_template(template) when is_binary(template) do
    Agent.update(TemplatesAgent, &Map.replace(&1, :state, template))
  end

  @doc """
  Updates the station URL template in the templates agent.

  ## Examples

      iex> alias NOAA.Observations.TemplatesAgent
      iex> template = "http://noaa.gov/display.php?stid=<%=station_id%>"
      iex> TemplatesAgent.update_station_template(template)
      iex> Agent.get(TemplatesAgent, & &1.station) == template
      true
  """
  @spec update_station_template(template) :: :ok
  def update_station_template(template) when is_binary(template) do
    Agent.update(TemplatesAgent, &Map.replace(&1, :station, template))
  end

  @doc """
  Refreshes the agent state from a config file.
  """
  @spec refresh :: :ok
  def refresh, do: Agent.update(TemplatesAgent, fn _state -> @templates end)

  ## Private functions

  # Returns a map of state and station URL templates
  @spec templates :: %{state: template, station: template}
  defp templates, do: @templates
end
