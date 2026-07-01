defmodule Mix.Tasks.GreenValidation.CompareStyles do
  @moduledoc """
  Joins the per-source artifacts into `style_sources/comparison.json`.
  """
  use Mix.Task

  alias GreenValidation.CLI.CompareStyles

  @shortdoc "Builds the cross-source style comparison"
  def run(args) do
    CompareStyles.main(args)
  end
end
