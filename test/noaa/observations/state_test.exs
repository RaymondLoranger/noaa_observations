defmodule NOAA.Observations.StateTest do
  # To ensure file-only logging.
  use ExUnit.Case, async: false

  alias NOAA.Observations.State

  doctest State

  describe "State.stations/1" do
    test ~S[detects "Moved Temporarily"] do
      alias NOAA.Observations.{State, TemplatesAgent}

      template =
        "https://www.weather.gov/xml/current_obs" <>
          "/seek.php?state=<%=state_code%>&Find=Find"

      :ok = TemplatesAgent.update_state_template(template)
      assert State.stations("VT") == {:error, 302, "Found (Moved Temporarily)"}
    end

    test ~S[detects "Not Found"] do
      alias NOAA.Observations.{State, TemplatesAgent}

      template =
        "https://forecast.weather.gov/xml/past_obs" <>
          "/seek.php?state=<%=state_code%>&Find=Find"

      :ok = TemplatesAgent.update_state_template(template)
      assert State.stations("VT") == {:error, 404, "Not Found"}
    end

    test ~S[detects "Connection Refused By Server"] do
      alias NOAA.Observations.{State, TemplatesAgent}
      template = "http://localhost:65535"
      :ok = TemplatesAgent.update_state_template(template)

      assert State.stations("VT") ==
               {:error, :econnrefused, "Connection Refused By Server"}
    end

    test ~S[detects "Address Not Available"] do
      alias NOAA.Observations.{State, TemplatesAgent}
      template = "http://localhost:0"
      :ok = TemplatesAgent.update_state_template(template)

      assert State.stations("VT") ==
               {:error, :eaddrnotavail, "Address Not Available"}
    end
  end
end
