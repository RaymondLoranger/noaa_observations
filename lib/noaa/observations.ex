# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations do
  @moduledoc """
  Fetches a list of weather observations for a US state/territory.
  """

  use PersistConfig

  alias __MODULE__.{Log, State, Station}

  @url_templates get_env(:url_templates)

  @doc """
  Fetches weather observations for a US `state`/territory.

  Returns a tuple of either `{:ok, [obs]}` or `{:error, text}`.

  ## Parameters

    - `state`         - US state/territory code
    - `url_templates` - URL templates (keyword)

  ## URL templates

    - `:state`   - URL template for a state (EEx string)
    - `:station` - URL template for a station (EEx string)

  ## Examples

      iex> alias NOAA.Observations
      iex> {:ok, observations} = Observations.fetch("vt")
      iex> Enum.all?(observations, &is_map/1) and length(observations) > 0
      true
  """
  @spec fetch(State.t(), Keyword.t()) ::
          {:ok, [Station.obs()]} | {:error, String.t()}
  def fetch(state, url_templates \\ @url_templates) do
    :ok = Log.info(:fetching_observations, {state, __ENV__})
    url_templates = Keyword.merge(@url_templates, url_templates)

    case State.stations(state, url_templates) do
      {:ok, stations} ->
        stations
        |> Enum.map(&Task.async(Station, :obs, [&1, url_templates]))
        |> Enum.map(&Task.await/1)
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        |> case do
          %{error: errors} -> {:error, List.first(errors)}
          %{ok: observations} -> {:ok, observations}
          %{} -> {:ok, []}
        end

      {:error, text} ->
        {:error, text}
    end
  end
end
