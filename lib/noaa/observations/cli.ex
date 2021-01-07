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

  @aliases get_env(:aliases)
  @count get_env(:default_count)
  @strict get_env(:strict)
  @switches get_env(:default_switches)
  @table_spec get_env(:table_spec)

  @type bell :: boolean
  @type count :: pos_integer
  @type parsed :: {State.t(), count, bell, Style.t()} | :help

  @doc """
  Parses the command line and prints a table of weather observations
  from the NOAA Weather Service.

  `argv` can be "-h" or "--help", which prints info on the command's
  usage and syntax. Otherwise it contains a `state` (case-insensitive) and
  optionally the number of observations to format (the first _n_ ones).
  To format the last _n_ observations, specify switch `--last`.
  To ring the bell, specify switch `--bell`.
  To choose a table style, specify switch `--table-style`.

  ## Parameters

    - `argv` - command line arguments (list)

  ## Switches

    - `-h` or `--help`        - for help
    - `-l` or `--last`        - to format the last _n_ issues
    - `-b` or `--bell`        - to ring the bell
    - `-t` or `--table-style` - to choose a table style

  ## Table styles

  #{Style.texts("\s\s- `&arg`&filler - &note\n")}
  """
  @spec main([String.t()]) :: :ok | no_return
  def main(argv) do
    case parse(argv) do
      {state, count, bell, style} ->
        case Observations.fetch(state) do
          {:ok, observations} ->
            :ok = Message.printing(state) |> IO.ANSI.format() |> IO.puts()
            :ok = Log.info(:printing, {state, __ENV__})
            options = [count: count, bell: bell, style: style]
            :ok = Table.write(observations, @table_spec, options)

          {:error, text} ->
            :ok = Message.error(state, text) |> IO.ANSI.format() |> IO.puts()
            :ok = Log.error(:fetching, {text, state})
            System.stop(1)
        end

      :help ->
        :ok = Help.show_help()
        System.stop(0)
    end
  end

  ## Private functions

  # @doc """
  # Parses `argv` (command line arguments). Returns either
  # a tuple of `{state, count, bell, table_style}` or `:help`.

  # ## Examples

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.parse ["-h"]
  #     :help

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.parse ["vt", "99"]
  #     {"vt", 99, false, :dark}

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.parse ["TX", "88", "--last", "--bell"]
  #     {"tx", -88, true, :dark}

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.parse ["nc", "6", "--table-style", "cyan"]
  #     {"nc", 6, false, :cyan}

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.parse ["nc", "0", "--table-style", "cyan"]
  #     :help
  # """
  @spec parse([String.t()]) :: parsed
  defp parse(argv) do
    argv
    |> OptionParser.parse(strict: @strict, aliases: @aliases)
    |> to_parsed()
  end

  # @doc """
  # Converts the output of `OptionParser.parse/2` to `parsed`.

  # ## Examples

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_parsed({[help: true], [], []})
  #     :help

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_parsed({[help: true], ["anything"], []})
  #     :help

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_parsed({[], ["st", "15"], []})
  #     {"st", 15, false, :dark}

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_parsed({[], ["st"], []})
  #     {"st", 13, false, :dark}

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_parsed({
  #     ...>   [last: true, bell: true, table_style: "dark-alt"],
  #     ...>   ["st", "18"],
  #     ...>   []
  #     ...> })
  #     {"st", -18, true, :dark_alt}
  # """
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

  # @doc """
  # Converts `args` to a tuple or `:error`.

  # ## Examples

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_tuple(["st", "7"])
  #     {"st", 7}

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_tuple(["st", "0"])
  #     :error

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_tuple([])
  #     :error

  #     iex> alias NOAA.Observations.CLI
  #     iex> CLI.to_tuple(["st"])
  #     {"st", 13}
  # """
  @spec to_tuple([String.t()]) :: {State.t(), pos_integer} | :error
  defp to_tuple([state, count] = _args) do
    with {int, ""} when int > 0 <- Integer.parse(count),
         do: {String.downcase(state), int},
         else: (_ -> :error)
  end

  defp to_tuple([state] = _args), do: {String.downcase(state), @count}
  defp to_tuple(_), do: :error
end
