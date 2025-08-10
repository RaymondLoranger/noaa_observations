defmodule NOAA.Observations.Help do
  @moduledoc """
  Prints info on the escript command's usage and syntax.

  Reference https://dev.to/paulasantamaria/command-line-interfaces-structure-syntax-2533
  """

  use PersistConfig

  alias IO.ANSI.Plus, as: ANSI
  alias IO.ANSI.Table.Style

  @default_count get_env(:default_count)
  @default_switches get_env(:default_switches)
  @escript Mix.Project.config()[:escript][:name]
  @help_attrs get_env(:help_attrs)

  @doc """
  Prints info on the escript command's usage and syntax.

  ## Examples

      no --help
      no vt 7 --last
      no tx --bell
      no ny -lb 8 -t green-border
      no ca -bl 9 --table-style=medium
      no fl -blt light
      no il
  """
  @spec print_help :: :ok
  def print_help do
    texts = ["usage:", " #{@escript}"]
    length = Enum.join(texts) |> String.length()
    filler = String.duplicate(" ", length)
    prefix = help_format([:section, :normal], texts)

    line_arguments =
      help_format([:arg], ["<us-state-or-territory-code> [<count>]"])

    line_flags = help_format([:switch], ["[-l | --last] [-b | --bell]"])

    line_table_style =
      help_format([:switch, :arg, :switch], [
        "[-t | --table-style ",
        "<table-style>",
        "]"
      ])

    line_where = help_format([:section], ["where:"])

    line_default_count =
      help_format([:normal, :arg, :normal, :value], [
        "  - default ",
        "<count>",
        " is ",
        "#{@default_count}"
      ])

    line_default_table_style =
      help_format([:normal, :arg, :normal, :value], [
        "  - default ",
        "<table-style>",
        " is ",
        "#{@default_switches[:table_style]}"
      ])

    line_table_style_one_of =
      help_format([:normal, :arg, :normal], [
        "  - ",
        "<table-style>",
        " is one of:"
      ])

    IO.write("""
    #{prefix} #{line_arguments}
    #{filler} #{line_flags}
    #{filler} #{line_table_style}
    #{line_where}
    #{line_default_count}
    #{line_default_table_style}
    #{line_table_style_one_of}
    """)

    template =
      help_format([:normal, :value, :normal], [
        "\s\s\s\s• ",
        "&arg",
        "&filler - &note"
      ])

    texts = Style.texts("#{template}")
    Enum.each(texts, &IO.puts/1)
  end

  ## Private functions

  @spec help_format([atom], [String.t()]) :: IO.chardata()
  defp help_format(types, texts) do
    Enum.map(types, &@help_attrs[&1])
    |> Enum.zip(texts)
    |> Enum.map(&Tuple.to_list/1)
    |> ANSI.format()
  end
end
