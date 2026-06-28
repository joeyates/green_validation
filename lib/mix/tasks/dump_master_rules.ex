defmodule Mix.Tasks.GreenValidation.DumpMasterRules do
  @moduledoc """
  Writes the master rule list to `style_sources/master_rules.json`.
  """
  use Mix.Task

  alias GreenValidation.CLI.DumpMasterRules

  @shortdoc "Dumps the master rule list to JSON"
  def run(args) do
    DumpMasterRules.main(args)
  end
end
