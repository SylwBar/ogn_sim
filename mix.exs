defmodule OgnSim.MixProject do
  use Mix.Project

  def project do
    [
      app: :ogn_sim,
      escript: escript_config(),
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OgnSim.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.2"},
      {:gen_stage, "~> 1.1"},
      {:poison, "~> 5.0"}
    ]
  end

  defp escript_config do
    [main_module: OGNSim.CLI]
  end
end
