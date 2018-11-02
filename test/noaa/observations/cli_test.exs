defmodule NOAA.Observations.CLITest do
  use ExUnit.Case, async: true
  use PersistConfig

  alias NOAA.Observations.CLI

  doctest CLI

  @count Application.get_env(@app, :default_count)

  describe "NOAA.Observations.CLI.parse/1" do
    test "returns :help with arguments -h or --help" do
      assert CLI.parse(["-h"]) == :help
      assert CLI.parse(["-h", "anything"]) == :help
      assert CLI.parse(["anything", "-h"]) == :help
      assert CLI.parse(["st", "--help"]) == :help
    end

    test "returns 4 values if 2 given" do
      assert CLI.parse(["STATE", "99"]) == {"state", 99, false, :dark}
    end

    test "defaults count if not given" do
      assert CLI.parse(["st"]) == {"st", @count, false, :dark}
      assert CLI.parse(["st", "--last"]) == {"st", -@count, false, :dark}
    end

    test "returns 4 values if 3 given" do
      assert CLI.parse(["st", "99", "--last"]) == {"st", -99, false, :dark}
      assert CLI.parse(["St", "--last", "99"]) == {"st", -99, false, :dark}
    end

    test "returns 4 values if count is zero" do
      assert CLI.parse(["st", "0"]) == {"st", 0, false, :dark}
      assert CLI.parse(["st", "0", "--last"]) == {"st", 0, false, :dark}
      assert CLI.parse(["st", "-0"]) == {"st", 0, false, :dark}
    end

    test "returns :help if count not positive integer" do
      assert CLI.parse(["st", "nine"]) == :help
      assert CLI.parse(["st", "-999"]) == :help
      assert CLI.parse(["st", "--bell", "-999"]) == :help
    end

    test "returns :help if table style invalid" do
      assert CLI.parse(["st", "-t", "DARK"]) == :help
      assert CLI.parse(["st", "-t", "Dark"]) == :help
    end
  end
end
