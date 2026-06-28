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

  @doc """
  Returns the sorted, unique line numbers of the lines changed by this change.

  The diff is the output of `mix format --check-formatted`, where each changed
  line is prefixed with its line number and a `-` (removed) or `+` (added)
  marker, e.g. ` 3    -|  x=1` and `    3 +|  x = 1`.
  """
  @spec line_numbers(t()) :: [pos_integer()]
  def line_numbers(%__MODULE__{diff: diff}) when is_binary(diff) do
    ~r/^ *(\d+) *[-+]\|/m
    |> Regex.scan(diff, capture: :all_but_first)
    |> Enum.map(fn [line] -> String.to_integer(line) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def line_numbers(%__MODULE__{}), do: []

  defimpl String.Chars do
    def to_string(%GreenValidation.Change{path: path, diff: diff}) do
      "#{path}:\n#{diff}"
    end
  end
end
