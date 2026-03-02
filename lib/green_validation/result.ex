defmodule GreenValidation.Result do
  @moduledoc """
  Defines the structure of validation results and provides functions to build and summarize them.

  The result includes:
  - metadata: Information about the validated project
  - baseline: Results of baseline formatting check
  - rules: Per-rule validation results with line-level details
  """

  alias GreenValidation.{RuleResult, TestRun}

  defstruct [:test_run, :baseline, rules: []]

  @type t :: %__MODULE__{
          test_run: TestRun.t(),
          baseline: [:clean | :created_format_commit],
          rules: list(RuleResult.t())
        }
end
