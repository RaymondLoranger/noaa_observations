defmodule NOAA.Observations.Mixfile do
  use Mix.Project

  def project do
    [ app: :noaa_observations,
      version: "0.1.6",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      name: "NOAA Observations",
      source_url: source_url(),
      description: description(),
      package: package(),
      aliases: aliases(),
      escript: escript_config(),
      deps: deps()
    ]
  end

  defp source_url do
    "https://github.com/RaymondLoranger/noaa_observations"
  end

  defp description do
    """
    Prints NOAA Observations to STDOUT in a table with borders and colors.
    """
  end

  defp package do
    [ maintainers: ["Raymond Loranger"],
      licenses: ["MIT"],
      links: %{"GitHub" => source_url()}
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :httpoison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [ {:io_ansi_table, "~> 0.1"},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:httpoison, "~> 0.11"},
      {:dialyxir, "== 0.4.4", only: :dev, runtime: false},
      {:logger_file_backend, "~> 0.0.9"}
    ]
  end

  defp aliases do
    [docs: ["docs", &copy_images/1]]
  end

  defp copy_images(_) do
    File.cp_r "images", "doc/images", fn src, dst -> src || dst # => true
      # IO.gets(~s|Overwriting "#{dst}" with "#{src}".\nProceed? [Yn]\s|)
      # in ["y\n", "Y\n"]
    end
  end

  defp escript_config do
    [main_module: NOAA.Observations.CLI, name: :no]
  end
end
