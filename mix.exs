defmodule Comadv.MixProject do
  use Mix.Project

  def project do
    [
      app: :comadv,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_ncurses, "~> 0.3"},
      {:matrix, "~> 0.3.0"}
    ]
  end
end
