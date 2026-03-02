defmodule GreenValidation.OutputParser do
  @moduledoc """
  Parses output from `mix format --check-formatted` to extract file names.
  """

  alias GreenValidation.{Repo, RuleResult}

  @doc """
  Parses the full mix format output and extracts file paths that have formatting issues.
  Converts absolute paths to repository-local paths.
  """
  @spec parse_output(Repo.t(), atom, String.t()) :: {:ok, %RuleResult{}}
  def parse_output(repo, rule, output) do
    changes_files = extract_changes_files(output)
    warnings_files = extract_warnings_files(output)

    # Convert absolute paths to repository-local paths
    path = Repo.path(repo)
    changes_files = Enum.map(changes_files, &make_repo_local(&1, path))
    warnings_files = Enum.map(warnings_files, &make_repo_local(&1, path))

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
    |> Enum.map(&String.trim_trailing(&1, "\e[0m"))
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

  # Converts absolute path to repository-local path
  # Example: /path/to/repos/elixir/lib/file.ex -> elixir/lib/file.ex
  defp make_repo_local(path, base_dir) do
    case String.split(path, base_dir, parts: 2) do
      [_, local_path] -> String.trim_leading(local_path, "/")
      _ -> path
    end
  end
end
