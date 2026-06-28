defmodule Mix.Tasks.GreenValidation.AnalyzeLexmag do
  @moduledoc """
  Analyses Lexmag's style guide and writes `style_sources/sources/lexmag.json`.
  """
  use Mix.Task

  alias GreenValidation.CLI.AnalyzeGuide
  alias GreenValidation.Sources.Lexmag

  @shortdoc "Analyses Lexmag's style guide"
  def run(args) do
    AnalyzeGuide.main(args, :lexmag, Lexmag.mapping())
  end
end
