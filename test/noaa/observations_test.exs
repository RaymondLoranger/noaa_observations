defmodule NOAA.ObservationsTest do
  use ExUnit.Case, async: false

  alias NOAA.Observations

  doctest Observations

  describe "Observations.fetch/1" do
    test ~S[detects "Moved Permanently"] do
      alias NOAA.Observations
      alias NOAA.Observations.TemplatesAgent

      template =
        "http://forecast.weather.gov/xml/current_obs" <>
          "/seek.php?state=<%=state_code%>&Find=Find"

      :ok = TemplatesAgent.update_state_template(template)

      {:error,
       %{
         state_code: "VT",
         state_name: "Vermont",
         state_url: url,
         error_code: 301,
         error_text: "Moved Permanently"
       }} = Observations.fetch("VT")

      assert url ==
               "http://forecast.weather.gov/xml/current_obs" <>
                 "/seek.php?state=VT&Find=Find"
    end

    test ~S[detects "Moved Temporarily"] do
      alias NOAA.Observations
      alias NOAA.Observations.TemplatesAgent

      template =
        "https://www.weather.gov/xml/current_obs" <>
          "/seek.php?state=<%=state_code%>&Find=Find"

      :ok = TemplatesAgent.update_state_template(template)

      {:error,
       %{
         state_code: "VT",
         state_name: "Vermont",
         state_url: url,
         error_code: 302,
         error_text: "Found (Moved Temporarily)"
       }} = Observations.fetch("VT")

      assert url ==
               "https://www.weather.gov/xml/current_obs" <>
                 "/seek.php?state=VT&Find=Find"
    end

    test ~S[detects "Not Found"] do
      alias NOAA.Observations
      alias NOAA.Observations.TemplatesAgent

      template =
        "https://forecast.weather.gov/xml/past_obs" <>
          "/seek.php?state=<%=state_code%>&Find=Find"

      :ok = TemplatesAgent.update_state_template(template)

      {:error,
       %{
         state_code: "VT",
         state_name: "Vermont",
         state_url: url,
         error_code: 404,
         error_text: "Not Found"
       }} =
        Observations.fetch("VT")

      assert url ==
               "https://forecast.weather.gov/xml/past_obs" <>
                 "/seek.php?state=VT&Find=Find"
    end

    test ~S[detects "Non-Existent Domain"] do
      alias NOAA.Observations
      alias NOAA.Observations.TemplatesAgent

      template =
        "htp://forecast.weather.gov/xml/current_obs" <>
          "/seek.php?state=<%=state_code%>&Find=Find"

      :ok = TemplatesAgent.update_state_template(template)

      {:error,
       %{
         state_code: "VT",
         state_name: "Vermont",
         state_url: url,
         error_code: :nxdomain,
         error_text: "Non-Existent Domain"
       }} = Observations.fetch("VT")

      assert url ==
               "htp://forecast.weather.gov/xml/current_obs" <>
                 "/seek.php?state=VT&Find=Find"
    end
  end
end
