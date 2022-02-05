# ┌───────────────────────────────────────────────────────────┐
# │ Exercise in the book "Programming Elixir" by Dave Thomas. │
# └───────────────────────────────────────────────────────────┘
defmodule NOAA.Observations.CLI do
  @moduledoc """
  Parses the command line and prints a table of weather observations
  from the NOAA Weather Service.

  ##### Exercise in the book [Programming Elixir](https://pragprog.com/book/elixir16/programming-elixir-1-6) by Dave Thomas.
  """

  use PersistConfig

  alias IO.ANSI.Table
  alias IO.ANSI.Table.Style
  alias NOAA.Observations
  alias NOAA.Observations.{Help, Log, Message, State}

  @count get_env(:default_count)
  @options get_env(:parsing_options)
  @switches get_env(:default_switches)
  @table_spec get_env(:table_spec)

  @doc """
  Parses the command line and prints a table of weather observations
  from the NOAA Weather Service.

  `argv` can be "-h" or "--help", which prints info on the command's
  usage and syntax. Otherwise it is a US state/territory code
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
  """
  @spec main(OptionParser.argv()) :: :ok
  def main(argv) do
    case OptionParser.parse(argv, @options) do
      {switches, args, []} -> :ok = maybe_write_table(switches, args)
      _ -> :ok = Help.show_help()
    end
  end

  ## Private functions

  @spec maybe_write_table(Keyword.t(), OptionParser.argv()) :: :ok
  defp maybe_write_table(switches, [state_code]) do
    maybe_write_table(switches, [state_code, @count])
  end

  defp maybe_write_table(switches, [state_code, count]) do
    with %{help: nil, bell: bell?, last: last?, table_style: style} <-
           Map.merge(@switches, Map.new(switches)),
         {:ok, style} <- Style.from_switch_arg(style),
         {count, ""} when count > 0 <- Integer.parse(count),
         count = if(last?, do: -count, else: count),
         options = [count: count, bell: bell?, style: style] do
      :ok = likely_write_table(state_code, options)
    else
      _error -> :ok = Help.show_help()
    end
  end

  defp maybe_write_table(_switches, _args) do
    :ok = Help.show_help()
  end

  @spec likely_write_table(State.code(), Keyword.t()) :: :ok
  defp likely_write_table(code, options) do
    case Observations.fetch(code) do
      {:ok, observations} ->
        :ok = Message.writing_table(code)
        :ok = Log.info(:writing_table, {code, __ENV__})
        :ok = Table.write(@table_spec, observations, options)

      {:error, text} ->
        :ok = Message.fetching_error(code, text)
        :ok = Log.error(:fetching_error, {code, text, __ENV__})
    end
  end
end
