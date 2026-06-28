defmodule Mix.Tasks.GreenValidation.FetchStyleGuides do
  @moduledoc """
  Downloads the prose style guides and vendors them under `style_sources/guides/`.
  """
  use Mix.Task

  alias GreenValidation.CLI.FetchStyleGuides

  @shortdoc "Vendors the prose style guides' markdown"
  def run(args) do
    FetchStyleGuides.main(args)
  end
end
