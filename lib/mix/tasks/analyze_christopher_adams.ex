defmodule Mix.Tasks.GreenValidation.AnalyzeChristopherAdams do
  @moduledoc """
  Analyses The Elixir Style Guide (christopheradams) and writes
  `style_sources/sources/christopher_adams.json`.
  """
  use Mix.Task

  alias GreenValidation.CLI.AnalyzeGuide
  alias GreenValidation.Sources.ChristopherAdams

  @shortdoc "Analyses The Elixir Style Guide"
  def run(args) do
    AnalyzeGuide.main(args, :christopher_adams, ChristopherAdams.mapping())
  end
end
