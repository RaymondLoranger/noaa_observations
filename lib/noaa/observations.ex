# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations do
  @moduledoc """
  Fetches weather observations for a US state/territory code.
  """

  use PersistConfig

  alias __MODULE__.{Log, State, Station}

  require Logger

  @url_templates get_env(:url_templates)

  @doc """
  Fetches weather observations for a US state/territory `code`.

  Returns either tuple `{:ok, [observation]}` or tuple `{:error, text}`.

  ## Examples

      iex> alias NOAA.Observations
      iex> {:ok, observations} = Observations.fetch("vt")
      iex> Enum.all?(observations, &is_map/1) and length(observations) > 0
      true
  """
  @spec fetch(State.code()) ::
          {:ok, [Station.observation()]} | {:error, String.t()}
  def fetch(code) do
    :ok = Log.info(:fetching_observations, {code, __ENV__})

    case State.stations(code, @url_templates) do
      {:ok, stations} ->
        stations
        |> remove_console()
        |> Enum.map(&Task.async(Station, :observation, [&1, @url_templates]))
        |> Enum.map(&Task.await/1)
        |> add_console()
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        |> case do
          %{error: errors} -> {:error, hd(errors)}
          %{ok: observations} -> {:ok, observations}
          %{} -> {:ok, []}
        end

      {:error, text} ->
        {:error, text}
    end
  end

  ## Private functions

  defp remove_console(stations) do
    Logger.remove_backend(:console)
    stations
  end

  defp add_console(observations) do
    Logger.add_backend(:console)
    observations
  end
end
