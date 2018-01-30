# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations.CLI do
  @moduledoc """
  Parses the command line and generates a table of
  observations from the NOAA Weather Service.
  """

  use PersistConfig

  alias IO.ANSI.Table
  alias IO.ANSI.Table.Style
  alias NOAA.Observations
  alias NOAA.Observations.Help

  require Logger

  @type bell :: boolean
  @type count :: integer
  @type parsed :: {state, count, bell, Style.t()} | :help
  @type state :: String.t()
  @type stn :: String.t()

  @aliases Application.get_env(@app, :aliases)
  @async Application.get_env(:io_ansi_table, :async)
  @count Application.get_env(@app, :default_count)
  @strict Application.get_env(@app, :strict)
  @switches Application.get_env(@app, :default_switches)

  @doc """
  Parses and processes `argv` (command line arguments).

  ## Parameters

    - `argv` - command line arguments (list)
  """
  @spec main([String.t()]) :: :ok | no_return
  def main(argv) do
    with {state, count, bell, style} <- parse(argv),
         {:ok, observations} <- Observations.fetch(state) do
      Table.format(observations, count: count, bell: bell, style: style)
      # Ensure table has printed before returning...
      Process.sleep((@async && 2000) || 0)
    else
      :help -> Help.show_help()
      {:error, text} -> log_error(text)
      any -> log_error("unknown: #{inspect(any)}")
    end
  end

  @doc """
  Parses `argv` (command line arguments).

  `argv` can be ["-h"] or ["--help"], which returns :help. Otherwise
  it contains a US state/territory code (case-insensitive) and optionally
  the number of observations to format (the first _n_ ones). To format the
  last _n_ observations, specify switch `--last` which will return a
  negative count. To ring the bell, specify switch `--bell`.
  To apply a specific table style, use switch `--table-style`.

  Returns either a tuple of {state, count, bell, table_style}
  or :help if `--help` was specified.

  ## Parameters

    - `argv` - command line arguments (list)

  ## Switches

    - `-h` or `--help`        - for help
    - `-l` or `--last`        - to format the last _n_ observations
    - `-b` or `--bell`        - to ring the bell
    - `-t` or `--table-style` - to apply a specific table style

  ## Table styles

  #{Style.texts("\s\s- `&arg`&filler - &note\n")}

  ## Examples

      iex> alias NOAA.Observations.CLI
      iex> CLI.parse ["-h"]
      :help

      iex> alias NOAA.Observations.CLI
      iex> CLI.parse ["vt", "99"]
      {"vt", 99, false, :dark}

      iex> alias NOAA.Observations.CLI
      iex> CLI.parse ["TX", "88", "--last", "--bell"]
      {"tx", -88, true, :dark}

      iex> alias NOAA.Observations.CLI
      iex> CLI.parse ["nc", "6", "--table-style", "cyan"]
      {"nc", 6, false, :cyan}
  """
  @spec parse([String.t()]) :: parsed
  def parse(argv) do
    argv
    |> OptionParser.parse(strict: @strict, aliases: @aliases)
    |> to_parsed()
  end

  ## Private functions

  @spec log_error(String.t()) :: no_return
  defp log_error(text) do
    Logger.error("Error fetching from NOAA - #{text}")
    # Ensure message logged before exiting...
    Process.sleep(1000)
    System.halt(2)
  end

  @spec to_parsed({Keyword.t(), [String.t()], [tuple]}) :: parsed
  defp to_parsed({switches, args, []}) do
    with {state, count} <- to_tuple(args),
         %{help: false, last: last, bell: bell, table_style: table_style} <-
           Map.merge(Map.new(@switches), Map.new(switches)),
         {:ok, style} <- Style.from_switch_arg(table_style),
         do: {state, (last && -count) || count, bell, style},
         else: (_ -> :help)
  end

  defp to_parsed(_), do: :help

  @spec to_tuple([String.t()]) :: {state, non_neg_integer} | :error
  defp to_tuple([state, count]) do
    with {int, ""} when int >= 0 <- Integer.parse(count),
         do: {String.downcase(state), int},
         else: (_ -> :error)
  end

  defp to_tuple([state]), do: {String.downcase(state), @count}
  defp to_tuple(_), do: :error
end
