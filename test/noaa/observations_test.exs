defmodule NOAA.ObservationsTest do
  use ExUnit.Case, async: true

  alias NOAA.Observations

  doctest Observations

  setup_all do
    # Prevents info messages...
    Logger.configure(level: :error)
  end

  describe "NOAA.Observations.fetch/2" do
    test ~S[error "reason: :econnrefused" if bad url given] do
      assert Observations.fetch("st", state: "http://localhost:1") ==
               {:error, "reason: :econnrefused"}
    end

    test ~S[error "reason: :nxdomain" if bad url given] do
      url =
        "http://w1.weather.org/xml/current_obs/seek.php?state={st}&Find=Find"

      assert Observations.fetch("vt", state: url) ==
               {:error, "reason: :nxdomain"}

      url = "htp://w1.weather.gov/xml/current_obs/seek.php?state={st}&Find=Find"

      assert Observations.fetch("vt", state: url) ==
               {:error, "reason: :nxdomain"}
    end

    test ~S[error "status code: 301 Moved Permanently" if bad url given] do
      url = "http://w1.weather.gov/xml/current_obs/display.php?stdid={stn}"

      assert Observations.fetch("vt", station: url) ==
               {:error, "status code: 301 ⇒ Moved Permanently"}
    end

    test ~S[error "status code: 404 Not Found" if bad url given] do
      url = "https://w1.weather.gov/xml/past_obs/display.php?stdid={stn}"

      assert Observations.fetch("vt", station: url) ==
               {:error, "status code: 404 ⇒ Not Found"}
    end
  end

  describe "NOAA.Observations.stations/2" do
    test ~S[error "reason: :econnrefused" if bad url given] do
      assert Observations.stations("st", state: "http://localhost:1") ==
               {:error, "reason: :econnrefused"}
    end

    test ~S[error "reason: :nxdomain" if bad url given] do
      url =
        "http://w1.weather.org/xml/current_obs/seek.php?state={st}&Find=Find"

      assert Observations.stations("vt", state: url) ==
               {:error, "reason: :nxdomain"}

      url = "htp://w1.weather.gov/xml/current_obs/seek.php?state={st}&Find=Find"

      assert Observations.stations("vt", state: url) ==
               {:error, "reason: :nxdomain"}
    end

    test ~S[error "status code: 302 Found" if close url given] do
      url =
        "https://www.weather.gov/xml/current_obs/seek.php?state={st}&Find=Find"

      assert Observations.stations("vt", state: url) ==
               {:error, "status code: 302 ⇒ Found"}
    end

    test ~S[error "status code: 404 Not Found" if bad url given] do
      url = "https://w1.weather.gov/xml/past_obs/seek.php?state={st}&Find=Find"

      assert Observations.stations("vt", state: url) ==
               {:error, "status code: 404 ⇒ Not Found"}
    end
  end

  describe "NOAA.Observations.obs/2" do
    test ~S[error "reason: :econnrefused" if bad url given] do
      url = "http://localhost:1"

      assert Observations.obs("KBTV", station: url) ==
               {:error, "reason: :econnrefused"}
    end

    test ~S[error "reason: :nxdomain" if bad url given] do
      url = "http://w1.weather.org/xml/current_obs/display.php?std={stn}"

      assert Observations.obs("KBTV", station: url) ==
               {:error, "reason: :nxdomain"}

      url = "htp://w1.weather.gov/xml/current_obs/display.php?std={stn}"

      assert Observations.obs("vt", station: url) ==
               {:error, "reason: :nxdomain"}
    end

    test ~S[error "status code: 302 Found" if close url given] do
      url = "https://www.weather.gov/xml/current_obs/display.php?stdid={stn}"

      assert Observations.obs("KBTV", station: url) ==
               {:error, "status code: 302 ⇒ Found"}
    end

    test ~S[error "status code: 404 Not Found" if bad url given] do
      url = "https://w1.weather.gov/xml/past_obs/display.php?stdid={stn}"

      assert Observations.obs("vt", station: url) ==
               {:error, "status code: 404 ⇒ Not Found"}
    end
  end
end
