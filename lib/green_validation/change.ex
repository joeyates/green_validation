defmodule GreenValidation.Change do
  @moduledoc """
  Represents a change detected by a Green rule, including the path and the diff.
  """

  @enforce_keys [:path, :diff]
  defstruct [:path, :diff]

  @type t :: %__MODULE__{
          path: String.t(),
          diff: String.t()
        }

  defimpl String.Chars do
    def to_string(%GreenValidation.Change{path: path, diff: diff}) do
      "#{path}:\n#{diff}"
    end
  end
end
