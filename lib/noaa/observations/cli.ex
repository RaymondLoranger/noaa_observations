
# Exercise in the book "Programming Elixir" by Dave Thomas.

defmodule NOAA.Observations.CLI do
  @moduledoc """
  Handles the command line parsing and the dispatch to
  the various functions that end up generating a table
  of the observations from the NOAA Weather Service.
  """

  alias IO.ANSI.Table.Formatter
  alias IO.ANSI.Table.Style
  alias NOAA.Observations

  @type parsed :: {String.t, integer, boolean, atom} | :help

  @app      Mix.Project.config[:app]
  @aliases  Application.get_env(@app, :aliases)
  @count    Application.get_env(@app, :default_count)
  @escript  Mix.Local.name_for(:escript, Mix.Project.config)
  @strict   Application.get_env(@app, :strict)
  @switches Application.get_env(@app, :default_switches)

  @doc """
  Parses and processes the command line arguments.

  ## Parameters

    - `argv` - command line arguments (list)
  """
  @spec main([String.t]) :: :ok | no_return
  def main(argv) do
    with {state, count, bell, style} <- parse(argv),
        {:ok, observations} <- Observations.fetch(state) do
      Formatter.print_table(observations, count, bell, style)
    else
      :help -> help()
      {:error, text} -> report_error(text)
    end
  end

  @spec report_error(String.t) :: no_return
  defp report_error(text) do
    IO.puts "Error fetching from NOAA - #{text}"
    System.halt(2)
  end

  @spec help :: no_return
  defp help do
    # Examples of usage on Windows:
    #   escript no --help
    #   escript no vt 7 --last
    #   escript no tx --bell
    #   escript no ny -lb 8 -t GREEN
    #   escript no ca -bl 9 --table-style=medium
    #   escript no fl -blt light
    # Examples of usage on macOS:
    #   ./issues no il
    prefix = case :os.type do
      {:win32, _} -> "usage: escript #{@escript}"
      ___________ -> "usage: ./#{@escript}"
    end
    filler = String.duplicate "\s", String.length(prefix)
    line_1 = "[(-h | --help)] <us-state-code>"
    line_2 = "[(-l | --last)] <count> [(-b | --bell)]"
    line_3 = "[(-t | --table-style)=<table-style>]"
    IO.write """
      #{prefix} #{line_1}
      #{filler} #{line_2}
      #{filler} #{line_3}
      where:
        - default <count> is #{@count}
        - default <table-style> is #{@switches[:table_style]}
        - <table-style> is one of:
      """
    Style.texts "\s\s\s\s• &tag&filler - &note", &IO.puts/1
    System.halt(0)
  end

  @doc """
  Parses the command line arguments.

  `argv` can be `-h` or `--help`, which returns `:help`. Otherwise it
  is a US state/territory code (case-insensitive) and optionally the
  number of observations to format (the first _n_ ones). To format the
  last _n_ observations, specify switch `--last` which will return a
  negative count.

  Returns either a tuple of `{state, count, bell, style}` or `:help`
  if `--help` was given.

  ## Parameters

    - `argv` - command line arguments (list)

  ## Switches

    - `-h` or `--help`        - for help
    - `-l` or `--last`        - to format the last _n_ observations
    - `-b` or `--bell`        - to ring the bell
    - `-t` or `--table-style` - to apply a specific table style

  ## Table styles

  #{Style.texts "\s\s- `&tag`&filler - &note\n"}
  ## Examples

      iex> alias NOAA.Observations.CLI
      iex> CLI.parse(["-h"])
      :help

      iex> alias NOAA.Observations.CLI
      iex> CLI.parse(["vt", "99"])
      {"vt", 99, false, :dark}

      iex> alias NOAA.Observations.CLI
      iex> CLI.parse(["TX", "88", "--last", "--bell"])
      {"tx", -88, true, :dark}

      iex> alias NOAA.Observations.CLI
      iex> CLI.parse(["nc", "6", "--table-style", "cyan"])
      {"nc", 6, false, :cyan}
  """
  @spec parse([String.t]) :: parsed
  def parse(argv) do
    argv
    |> OptionParser.parse(strict: @strict, aliases: @aliases)
    |> reformat
  end

  @spec reformat({Keyword.t, [String.t], [tuple]}) :: parsed
  defp reformat({switches, args, []}) do
    with {state, count} <- normalize(args),
        %{
          help: false, last: last, bell: bell, table_style: table_style
        } <- Map.merge(Map.new(@switches), Map.new(switches)),
        {:ok, style} <- Style.style_for(table_style) do
      {state, last && -count || count, bell, style}
    else
      _ -> :help
    end
  end
  defp reformat(_), do: :help

  @spec normalize([String.t]) :: {String.t, non_neg_integer} | :error
  defp normalize([state, count]) do
    with {int, ""} when int >= 0 <- Integer.parse(count) do
      {String.downcase(state), int}
    else
      _ -> :error
    end
  end
  defp normalize([state]), do: {String.downcase(state), @count}
  defp normalize(_), do: :error
end
