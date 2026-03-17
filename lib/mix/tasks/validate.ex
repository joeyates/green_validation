defmodule Mix.Tasks.GreenValidation.Validate do
  @moduledoc """
  Runs the validator.
  """
  use Mix.Task

  alias GreenValidation.CLI.Validate

  @shortdoc "Run the validator"
  def run(args) do
    Validate.main(args)
  end
end
