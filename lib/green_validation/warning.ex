defmodule GreenValidation.Warning do
  @moduledoc """
  Represents a warning emitted by a Green rule, including the file and line number where it occurred.
  """

  @enforce_keys [:code, :file, :line, :message]
  defstruct [:code, :file, :line, :message]

  @type t :: %__MODULE__{
          code: String.t(),
          file: String.t(),
          line: non_neg_integer(),
          message: String.t()
        }

  defimpl String.Chars do
    def to_string(%GreenValidation.Warning{file: file, line: line, message: message, code: code}) do
      "#{file}:#{line} - #{message}: #{code}"
    end
  end
end
