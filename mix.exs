defmodule HLDSLogs.MixProject do
  use Mix.Project

  def project do
    [
      app: :hlds_logs,
      version: "0.1.1",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      description: description(),
      package: package(),
      name: "HLDSLogs",
      source_url: "https://github.com/JonnyPower/hlds_logs",
      docs: [
        main: "HLDSLogs",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :hlds_rcon],
      mod: {HLDSLogs.Application, []}
    ]
  end

  def description do
    "A library for connecting to HLDS servers and using GenStage to produce structured log entries."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:gen_stage, "~> 0.14.1"},
      {:hlds_rcon, "~> 1.0.1"}
    ]
  end

  defp package do
    [
      licenses: ["MIT License"],
      links: %{
        "GitHub" => "https://github.com/JonnyPower/hlds_logs"
      }
    ]
  end
end
