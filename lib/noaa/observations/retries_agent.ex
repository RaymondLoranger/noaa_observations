defmodule NOAA.Observations.RetriesAgent do
  @moduledoc """
  An agent process loading the maximum number of timeout retries.
  """

  use Agent
  use PersistConfig

  alias __MODULE__

  @retries get_env(:timeout_retries)

  @doc """
  Spawns an agent process that loads the maximum number of timeout retries.

  ## Examples

      iex> alias NOAA.Observations.RetriesAgent
      iex> {:error, {:already_started, agent}} = RetriesAgent.start_link(:ok)
      iex> is_pid(agent) and agent == Process.whereis(RetriesAgent)
      true
  """
  @spec start_link(term) :: Agent.on_start()
  def start_link(_arg = :ok) do
    Agent.start_link(&retries/0, name: RetriesAgent)
  end

  @doc """
  Gets and decrements the number of timeout retries in the retries agent.

  ## Examples

      iex> alias NOAA.Observations.RetriesAgent
      iex> RetriesAgent.refresh()
      iex> bef_retries = RetriesAgent.get_and_decrement()
      iex> aft_retries = Agent.get(& &1)
      iex> aft_retries = bef_retries - 1
      true
  """
  @spec get_and_decrement :: non_neg_integer
  def get_and_decrement do
    Agent.get_and_update(RetriesAgent, fn retries -> {retries, retries - 1} end)
  end

  @doc """
  Refreshes the agent state.
  """
  @spec refresh :: :ok
  def refresh, do: Agent.update(RetriesAgent, fn _retries -> @retries end)

  ## Private functions

  # Returns the maximum number of timeout retries.
  @spec retries :: pos_integer
  defp retries, do: @retries
end
