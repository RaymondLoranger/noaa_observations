
# Exercise in the book "Programming Elixir" by Dave Thomas.

defmodule NOAA.Observations.CLI do
  @moduledoc """
  Handles the command line parsing and the dispatch to
  the various functions that end up generating a table
  of observations from the NOAA Weather Service.
  """

  import Logger, only: [error: 1]

  alias IO.ANSI.Table.{Formatter, Style}
  alias NOAA.Observations

  @type parsed :: {String.t, integer, boolean, atom} | :help

  @app        Mix.Project.config[:app]
  @aliases    Application.get_env(@app, :aliases)
  @count      Application.get_env(@app, :default_count)
  @escript    Mix.Local.name_for(:escript, Mix.Project.config)
  @help_attrs Application.get_env(@app, :help_attrs)
  @strict     Application.get_env(@app, :strict)
  @switches   Application.get_env(@app, :default_switches)

  @doc """
  Parses and processes the command line arguments.

  ## Parameters

    - `argv` - command line arguments (list)
  """
  @spec main([String.t]) :: :ok | no_return
  def main(argv) do
    with {state, count, bell, style} <- parse(argv),
      {:ok, observations} <- Observations.fetch(state)
    do
      Formatter.print_table(observations, count, bell, style)
    else
      :help -> help()
      {:error, text} -> log_error(text)
    end
  end

  @spec log_error(String.t) :: no_return
  defp log_error(text) do
    error "Error fetching from NOAA - #{text}"
    Process.sleep(1_000) # ensure message logged before exiting
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
    {types, texts} = case :os.type do
      {:win32, _} ->
        { [:section, :normal, :command, :normal],
          ["usage:", " ", "escript", " #{@escript}"]
        }
      _ -> # e.g. {:unix, _}
        { [:section, :normal],
          ["usage:", " ./#{@escript}"]
        }
    end
    filler = String.duplicate " ", String.length Enum.join(texts)
    prefix = help_format(types, texts)
    line_1 = help_format(
      [:switch, :arg],
      ["[(-h | --help)] ", "<us-state-code>"]
    )
    line_2 = help_format(
      [:switch, :normal, :arg, :normal, :switch],
      ["[(-l | --last)]", " ", "<count>", " ", "[(-b | --bell)]"]
    )
    line_3 = help_format(
      [:switch, :arg, :switch],
      ["[(-t | --table-style)=", "<table-style>", "]"]
    )
    line_4 = help_format(
      [:section],
      ["where:"]
    )
    line_5 = help_format(
      [:normal, :arg, :normal],
      ["  - default ", "<count>", " is #{@count}"]
    )
    line_6 = help_format(
      [:normal, :arg, :normal, :value],
      ["  - default ", "<table-style>", " is ", "#{@switches[:table_style]}"]
    )
    line_7 = help_format(
      [:normal, :arg, :normal],
      ["  - ", "<table-style>", " is one of:"]
    )
    IO.write """
      #{prefix} #{line_1}
      #{filler} #{line_2}
      #{filler} #{line_3}
      #{line_4}
      #{line_5}
      #{line_6}
      #{line_7}
      """
    template = help_format(
      [:normal, :value, :normal],
      ["\s\s\s\s• ", "&tag", "&filler - &note"]
    )
    Style.texts "#{template}", &IO.puts/1
    System.halt(0)
  end

  @spec help_format([atom], [String.t]) :: maybe_improper_list
  defp help_format(types, texts) do
    types
    |> Enum.map(&@help_attrs[&1])
    |> Enum.zip(texts)
    |> Enum.map(&Tuple.to_list/1)
    |> IO.ANSI.format
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
      %{help: false, last: last, bell: bell, table_style: table_style}
      <- Map.merge(Map.new(@switches), Map.new(switches)),
      {:ok, style} <- Style.style_for(table_style)
    do
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
