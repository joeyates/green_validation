defmodule GreenValidation.RuleResult do
  @moduledoc """
  Represents the result of validating a single rule against a project, including the rule name, overall status, and line-level results.
  """

  @enforce_keys [:rule]
  defstruct [:rule, changes: [], warnings: []]

  @type t :: %__MODULE__{
          rule: atom(),
          changes: list(String.t()),
          warnings: list(String.t())
        }
end
