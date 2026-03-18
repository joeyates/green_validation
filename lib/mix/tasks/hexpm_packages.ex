defmodule Mix.Tasks.GreenValidation.HexpmPackages do
  @moduledoc """
  Downloads a list of popular Hex.pm packages.
  """
  use Mix.Task

  alias GreenValidation.CLI.HexpmPackages

  @shortdoc "Download a list of popular Hex.pm packages"
  def run(args) do
    Mix.Task.run("app.start")
    HexpmPackages.main(args)
  end
end
