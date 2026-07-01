defmodule Mix.Tasks.GreenValidation.ComparisonPdf do
  @moduledoc """
  Renders the style comparison to `style_sources/comparison.pdf`.
  """
  use Mix.Task

  alias GreenValidation.CLI.ComparisonPdf

  @shortdoc "Renders the style comparison as a PDF"
  def run(args) do
    ComparisonPdf.main(args)
  end
end
