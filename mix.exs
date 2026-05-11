defmodule MeuBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :meu_bot,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MeuBot, []}
    ]
  end

  defp deps do
    [
      {:nostrum, "~> 0.9"},
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
