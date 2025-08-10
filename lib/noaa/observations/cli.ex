# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations.CLI do
  @moduledoc """
  Parses the command line and prints a table of weather observations from the
  NOAA Weather Service.

  ##### Exercise in the book [Programming Elixir](https://pragprog.com/book/elixir16/programming-elixir-1-6) by Dave Thomas.

  ##### Reference https://dev.to/paulasantamaria/command-line-interfaces-structure-syntax-2533
  """

  use PersistConfig

  alias IO.ANSI.Table
  alias IO.ANSI.Table.Style
  alias NOAA.Observations
  alias NOAA.Observations.{Help, Log, Message, State, Station}

  @default_count get_env(:default_count)
  @default_switches get_env(:default_switches)
  @observations_spec get_env(:observations_spec)
  @parsing_options get_env(:parsing_options)
  @state_error_spec get_env(:state_error_spec)
  @stations_spec get_env(:stations_spec)

  @typedoc "NOAA weather observations"
  @type observations :: [Station.observation()]
  @typedoc "Station errors"
  @type station_errors :: [Station.error()]

  @doc """
  Parses the command line and prints a table of weather observations from the
  NOAA Weather Service.

  `argv` can be "-h" or "--help", which prints info on the command's
  usage and syntax. Otherwise it is a US state/territory code
  (case-insensitive) and optionally the number of observations
  to format (the first _n_ ones).

  To format the last _n_ observations, specify switch `--last`.
  To ring the bell, specify switch `--bell`.
  To choose a table style, specify switch `--table-style`.

  ## Parameters

    - `argv` - command line arguments (list)

  ## Switches

    - `-h` or `--help`        - for help
    - `-b` or `--bell`        - to ring the bell
    - `-l` or `--last`        - to format the last _n_ observations
    - `-t` or `--table-style` - to choose a table style

  ## Table styles

  #{Style.texts("\s\s- `&arg`&filler - &note\n")}

  ## Examples

      alias NOAA.Observations.CLI
      CLI.main(["fl", "--last", "--no-help"])
      CLI.main(["tx", "--no-last"])
      CLI.main(["VT", "--no-bell", "--table-style", "plain"])
      CLI.main(["ca", "11", "--last"])
      CLI.main(["CA", "--last", "11"])
  """
  @spec main(OptionParser.argv()) :: :ok
  def main(argv) do
    case OptionParser.parse(argv, @parsing_options) do
      {switches, args, []} -> :ok = maybe_write_table(switches, args)
      _invalid -> :ok = Help.print_help()
    end
  end

  @doc """
  Allows to run command `mix run -e 'NOAA.Observations.CLI.main()'`.

  The above command is equivalent to:\s\s
  `mix run -e 'NOAA.Observations.CLI.main([""ny"", ""16"", ""-t"", ""plain""])'`

  ## Examples

      $env:MIX_ENV="test"; mix run -e 'NOAA.Observations.CLI.main()'
      $env:MIX_ENV="dev"; mix run -e 'NOAA.Observations.CLI.main()'
      $env:MIX_ENV="prod"; mix run -e 'NOAA.Observations.CLI.main()'
      $env:AWAIT_TIMEOUT="111"; mix run -e 'NOAA.Observations.CLI.main()'
  """
  @spec main :: :ok
  def main do
    :ok = main(["ny", "16", "-t", "plain"])
  end

  ## Private functions

  @spec maybe_write_table(keyword, OptionParser.argv()) :: :ok
  defp maybe_write_table(switches, [state_code]) do
    maybe_write_table(switches, [state_code, @default_count])
  end

  defp maybe_write_table(switches, [state_code, count]) do
    with %{help: false, bell: bell?, last: last?, table_style: style} <-
           Map.merge(@default_switches, Map.new(switches)),
         {:ok, style} <- Style.from_switch_arg(style),
         {count, ""} when count > 0 <- Integer.parse(count),
         count = if(last?, do: -count, else: count),
         options = [count: count, bell: bell?, style: style] do
      :ok = String.upcase(state_code) |> write_table(options)
    else
      :error -> :ok = Help.print_help()
    end
  end

  defp maybe_write_table(_switches, _args) do
    :ok = Help.print_help()
  end

  @dialyzer {:nowarn_function, [write_table: 2]}
  @spec write_table(State.code(), keyword) :: :ok
  defp write_table(state_code, options) do
    case Observations.fetch(state_code, options) do
      %{ok: observations, error: station_errors} ->
        :ok = write_stations_table(station_errors, adjust(options), state_code)
        :ok = write_observations_table(observations, options, state_code)

      %{ok: observations} ->
        :ok = write_observations_table(observations, options, state_code)

      %{error: station_errors} ->
        :ok = write_stations_table(station_errors, adjust(options), state_code)

      {:error, state_error} ->
        :ok = write_state_error_table(state_error, options, state_code)

      %{} ->
        :ok = write_observations_table([], options, state_code)
    end
  end

  @dialyzer {:nowarn_function, [write_stations_table: 3]}
  @spec write_stations_table(station_errors, keyword, State.code()) :: :ok
  defp write_stations_table(station_errors, options, state_code) do
    :ok = Log.info(:writing_stations_table, {state_code, __ENV__})
    :ok = Message.writing_stations_table(state_code)
    :ok = Table.write(@stations_spec, station_errors, options)
  end

  @dialyzer {:nowarn_function, [write_state_error_table: 3]}
  @spec write_state_error_table(State.error(), keyword, State.code()) :: :ok
  defp write_state_error_table(state_error, options, state_code) do
    :ok = Log.info(:writing_state_error_table, {state_error, __ENV__})
    :ok = Message.writing_state_error_table(state_code)
    :ok = Table.write(@state_error_spec, [state_error], options)
  end

  @dialyzer {:nowarn_function, [write_observations_table: 3]}
  @spec write_observations_table(observations, keyword, State.code()) :: :ok
  defp write_observations_table(observations, options, state_code) do
    :ok = Log.info(:writing_observations_table, {state_code, __ENV__})
    :ok = Message.writing_observations_table(state_code)
    :ok = Table.write(@observations_spec, observations, options)
  end

  @spec adjust(keyword) :: keyword
  defp adjust(options), do: put_in(options[:count], 999)
end
