defmodule GreenValidation.OutputParser do
  @moduledoc """
  Parses output from `mix format --check-formatted` to extract file names.
  """

  alias GreenValidation.RuleResult

  @doc """
  Parses the full mix format output and extracts file paths that have formatting issues.
  """
  @spec parse_output(atom, String.t()) :: {:ok, %RuleResult{}}
  def parse_output(rule, output) do
    changes_files = extract_changes_files(output)
    warnings_files = extract_warnings_files(output)

    {
      :ok,
      %RuleResult{
        rule: rule,
        changes: changes_files,
        warnings: warnings_files
      }
    }
  end

  # Changes are preceded by an ANSI escape code for red text and then a file name
  defp extract_changes_files(output) do
    output
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "\e[1m\e[31m"))
    |> Enum.map(&String.trim_leading(&1, "\e[1m\e[31m"))
    |> Enum.uniq()
  end

  # Warnings look like this:
  # └─ test/eex_test.exs:
  defp extract_warnings_files(output) do
    output
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "└─ "))
    |> Enum.map(&String.trim_leading(&1, "└─ "))
    |> Enum.map(&String.replace(&1, ~r":.*", ""))
    |> Enum.uniq()
  end
end
