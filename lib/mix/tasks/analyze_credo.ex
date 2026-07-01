defmodule Mix.Tasks.GreenValidation.AnalyzeCredo do
  @moduledoc """
  Analyses Credo's style guide and writes `style_sources/sources/credo.json`.
  """
  use Mix.Task

  alias GreenValidation.CLI.AnalyzeGuide
  alias GreenValidation.Sources.Credo

  @shortdoc "Analyses Credo's style guide"
  def run(args) do
    AnalyzeGuide.main(args, :credo, Credo.mapping())
  end
end
