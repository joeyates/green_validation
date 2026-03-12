defmodule GreenValidation.RuleResult do
  @moduledoc """
  Represents the result of validating a single rule against a project, including the rule name, overall status, and line-level results.
  """

  alias GreenValidation.{Change, Warning}

  @enforce_keys [:rule]
  defstruct [:rule, changes: [], warnings: []]

  @type t :: %__MODULE__{
          rule: atom(),
          changes: list(Change.t()),
          warnings: list(Warning.t())
        }
end
