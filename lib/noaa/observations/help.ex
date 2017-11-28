defmodule NOAA.Observations.Help do
  @moduledoc false

  use PersistConfig

  alias IO.ANSI.Table.Style

  @count Application.get_env(@app, :default_count)
  @escript Mix.Local.name_for(:escript, Mix.Project.config())
  @help_attrs Application.get_env(@app, :help_attrs)
  @switches Application.get_env(@app, :default_switches)

  @spec show_help() :: no_return
  def show_help() do
    # Examples of usage on Windows:
    #   escript no --help
    #   escript no vt 7 --last
    #   escript no tx --bell
    #   escript no ny -lb 8 -t green-border
    #   escript no ca -bl 9 --table-style=medium
    #   escript no fl -blt light
    # Examples of usage on macOS:
    #   ./issues no il
    {types, texts} =
      case :os.type() do
        {:win32, _} ->
          {
            [:section, :normal, :command, :normal],
            ["usage:", " ", "escript", " #{@escript}"]
          }
        {:unix, _} ->
          {
            [:section, :normal],
            ["usage:", " ./#{@escript}"]
          }
      end
    filler = " " |> String.duplicate(texts |> Enum.join() |> String.length())
    prefix = help_format(types, texts)
    line_us_state_code =
      help_format(
        [:switch, :arg],
        ["[(-h | --help)] ", "<us-state-code>"]
      )
    line_count =
      help_format(
        [:switch, :normal, :arg, :normal, :switch],
        ["[(-l | --last)]", " ", "<count>", " ", "[(-b | --bell)]"]
      )
    line_table_style =
      help_format(
        [:switch, :arg, :switch],
        ["[(-t | --table-style)=", "<table-style>", "]"]
      )
    line_where =
      help_format(
        [:section],
        ["where:"]
      )
    line_default_count =
      help_format(
        [:normal, :arg, :normal, :value],
        ["  - default ", "<count>", " is ", "#{@count}"]
      )
    line_default_table_style =
      help_format(
        [:normal, :arg, :normal, :value],
        ["  - default ", "<table-style>", " is ", "#{@switches[:table_style]}"]
      )
    line_table_style_one_of =
      help_format(
        [:normal, :arg, :normal],
        ["  - ", "<table-style>", " is one of:"]
      )
    IO.write(
      """
      #{prefix} #{line_us_state_code}
      #{filler} #{line_count}
      #{filler} #{line_table_style}
      #{line_where}
      #{line_default_count}
      #{line_default_table_style}
      #{line_table_style_one_of}
      """
    )
    template =
      help_format(
        [:normal, :value, :normal],
        ["\s\s\s\s• ", "&arg", "&filler - &note"]
      )
    Style.texts("#{template}", &IO.puts/1)
    System.halt(0)
  end

  @spec help_format([atom], [String.t]) :: IO.chardata
  defp help_format(types, texts) do
    types
    |> Enum.map(&@help_attrs[&1])
    |> Enum.zip(texts)
    |> Enum.map(&Tuple.to_list/1)
    |> IO.ANSI.format()
  end
end
