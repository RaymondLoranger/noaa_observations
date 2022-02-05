defmodule NOAA.Observations.Mixfile do
  use Mix.Project

  def project do
    [
      app: :noaa_observations,
      version: "0.4.45",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      name: "NOAA Observations",
      source_url: source_url(),
      description: description(),
      package: package(),
      # aliases: aliases(),
      escript: escript(),
      deps: deps(),
      # See NOAA.Observations.CLI.main/1...
      # See NOAA.Observations.url/2...
      dialyzer: [plt_add_apps: [:io_ansi_table, :eex]]
    ]
  end

  defp source_url do
    "https://github.com/RaymondLoranger/noaa_observations"
  end

  defp description do
    """
    Writes NOAA Observations to "stdio" in a table with borders and colors.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "config/persist*.exs"],
      maintainers: ["Raymond Loranger"],
      licenses: ["MIT"],
      links: %{"GitHub" => source_url()}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # Only using the `IO.ANSI.Table.write/3` function.
      included_applications: [:io_ansi_table, :eex],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:file_only_logger, "~> 0.1"},
      {:httpoison, "~> 1.0"},
      {:io_ansi_table, "~> 1.0"},
      {:log_reset, "~> 0.1"},
      {:persist_config, "~> 0.4", runtime: false}
    ]
  end

  # defp aliases do
  #   [
  #     docs: ["docs", &copy_images/1]
  #   ]
  # end

  # defp copy_images(_) do
  #   File.cp_r("images", "doc/images", fn src, dst ->
  #     # Always true...
  #     src || dst

  #     # IO.gets(~s|Overwriting "#{dst}" with "#{src}".\nProceed? [Yn]\s|) in [
  #     #   "y\n",
  #     #   "Y\n"
  #     # ]
  #   end)
  # end

  defp escript do
    [
      main_module: NOAA.Observations.CLI,
      name: :no
    ]
  end
end
