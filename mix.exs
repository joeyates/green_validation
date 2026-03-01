defmodule Green.Validation.MixProject do
  use Mix.Project

  def project() do
    [
      app: :green_validation,
      version: "0.0.1",
      elixir: "~> 1.14",
      deps: deps(),
      description: "Run Green's validation checks on Elixir code",
      elixirc_paths: ["lib"]
    ]
  end

  defp deps() do
    [
      {:helpful_options, "~> 0.4.4"},
      {:jason, "~> 1.4"}
    ]
  end
end
