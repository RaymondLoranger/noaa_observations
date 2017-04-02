
defmodule NOAA.ObservationsTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias NOAA.Observations

  doctest Observations

  setup_all do
    Logger.configure level: :error # prevents info logging
  end

  describe "NOAA.Observations.fetch/2" do
    test ~S[error "reason: :econnrefused" if bad url given] do
      assert Observations.fetch(
        "st", url_templates: %{state: "http://localhost:1"}
      ) == {:error, "reason: :econnrefused"}
    end

    test ~S[error "reason: :nxdomain" if bad url given] do
      assert Observations.fetch("vt", url_templates: %{
        state: "http://w1.weather.org/xml/current_obs/" <>
          "seek.php?state={st}&Find=Find"
      }) == {:error, "reason: :nxdomain"}
    end

    test ~S[error "status code: 302 (not found)" if bad url given?] do
      assert Observations.fetch("vt", url_templates: %{
        station: "http://www.weather.gov/xml/current_obs/{stn}.xml"
      }) in [
        error: "status code: 302 (not found)",
        error: "reason: :connect_timeout",
        error: "reason: {:tls_alert, 'handshake failure'}",
        error: "unknown error"
      ]
    end

    test ~S[error "status code: 404 (not found)" if bad url given?] do
      assert Observations.fetch("vt", url_templates: %{
        station: "http://w1.weather.gov/xml/past_obs/{stn}.xml"
      }) in [
        error: "status code: 404 (not found)",
        error: "reason: :connect_timeout"
      ]
    end

    test ~S[error "exception: argument error" if bad url given] do
      assert Observations.fetch("vt", url_templates: %{
        state: "htp://w1.weather.gov/xml/current_obs/" <>
          "seek.php?state={st}&Find=Find"
      }) == {:error, "exception: argument error"}
    end
  end

  describe "NOAA.Observations.stations/2" do
    test ~S[error "reason: :econnrefused" if bad url given] do
      assert Observations.stations("st", %{state: "http://localhost:1"})
      == {:error, "reason: :econnrefused"}
    end

    test ~S[error "reason: :nxdomain" if bad url given] do
      assert Observations.stations("vt", %{
        state: "http://w1.weather.org/xml/current_obs/" <>
          "seek.php?state={st}&Find=Find"
      }) == {:error, "reason: :nxdomain"}
    end

    test ~S[error "status code: 302 (not found)" if bad url given?] do
      assert Observations.stations("vt", %{
        state: "http://www.weather.gov/xml/current_obs/" <>
          "seek.php?state={st}&Find=Find"
      }) in [
        error: "status code: 302 (not found)",
        error: "reason: :connect_timeout",
        error: "reason: {:tls_alert, 'handshake failure'}",
        error: "unknown error"
      ]
    end

    test ~S[error "status code: 404 (not found)" if bad url given?] do
      assert Observations.stations("vt", %{
        state: "http://w1.weather.gov/xml/past_obs/" <>
          "seek.php?state={st}&Find=Find"
      }) in [
        error: "status code: 404 (not found)",
        error: "reason: :connect_timeout"
      ]
    end

    test ~S[error "exception: argument error" if bad url given] do
      assert Observations.stations("vt", %{
        state: "htp://w1.weather.gov/xml/current_obs/" <>
          "seek.php?state={st}&Find=Find"
      }) == {:error, "exception: argument error"}
    end
  end

  describe "NOAA.Observations.observation/2" do
    test ~S[error "reason: :econnrefused" if bad url given] do
      assert Observations.observation("KBTV", %{station: "http://localhost:1"})
      == {:error, "reason: :econnrefused"}
    end

    test ~S[error "reason: :nxdomain" if bad url given] do
      assert Observations.observation("KBTV", %{
        station: "http://w1.weather.org/xml/current_obs/{stn}.xml"
      }) == {:error, "reason: :nxdomain"}
    end

    test ~S[error "status code: 302 (not found)" if bad url given?] do
      assert Observations.observation("KBTV", %{
        station: "http://www.weather.gov/xml/current_obs/{stn}.xml"
      }) in [
        error: "status code: 302 (not found)",
        error: "reason: :connect_timeout",
        error: "reason: {:tls_alert, 'handshake failure'}",
        error: "unknown error"
      ]
    end

    test ~S[error "status code: 404 (not found)" if bad url given?] do
      assert Observations.observation("vt", %{
        station: "http://w1.weather.gov/xml/past_obs/{stn}.xml"
      }) in [
        error: "status code: 404 (not found)",
        error: "reason: :connect_timeout"
      ]
    end

    test ~S[error "exception: argument error" if bad url given] do
      assert Observations.observation("vt", %{
        station: "htp://w1.weather.gov/xml/current_obs/{stn}.xml"
      }) == {:error, "exception: argument error"}
    end
  end
end
