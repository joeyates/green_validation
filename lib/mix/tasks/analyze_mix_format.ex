defmodule Mix.Tasks.GreenValidation.AnalyzeMixFormat do
  @moduledoc """
  Analyses which master rules `mix format` enforces and writes
  `style_sources/sources/mix_format.json`.
  """
  use Mix.Task

  alias GreenValidation.CLI.AnalyzeMixFormat

  @shortdoc "Analyses mix format's enforced rules"
  def run(args) do
    AnalyzeMixFormat.main(args)
  end
end
