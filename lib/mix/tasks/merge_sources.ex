defmodule Mix.Tasks.GreenValidation.MergeSources do
  @moduledoc """
  Merges downlaoded lists of popular Elixir repositories into a single list of unique repositories.
  """
  use Mix.Task

  alias GreenValidation.CLI.MergeSources

  @shortdoc "Merges the downloaded lists"
  def run(args) do
    MergeSources.main(args)
  end
end
