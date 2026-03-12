defmodule GreenValidation.OutputParser do
  @moduledoc """
  Parses output from `mix format --check-formatted` to extract file names.
  """

  alias GreenValidation.{Change, Project, RuleResult, Warning}

  @doc """
  Parses the full mix format output and extracts file paths that have formatting issues.
  Converts absolute paths to repository-local paths.
  """
  @spec parse_output(Project.t(), atom, String.t()) :: {:ok, %RuleResult{}}
  def parse_output(project, rule, output) do
    path = Project.path(project)
    changes = extract_changes(output, path)
    warnings = extract_warnings(output)

    {
      :ok,
      %RuleResult{
        rule: rule,
        changes: changes,
        warnings: warnings
      }
    }
  end

  # Changes are preceded by an ANSI escape code for red text and then a file name,
  # followed by the diff of the changes.
  @spec extract_changes(String.t(), Path.t()) :: list(Change.t())
  defp extract_changes(output, root) do
    regex = ~r/
      \e\[1m\e\[31m(?<path>[^\n]+)\n
      \e\[0m\n
      (?<diff>[^\e]*)
    /sx

    regex
    |> Regex.scan(output, capture: [:path, :diff])
    |> Enum.map(fn [path, diff] ->
      local_path = make_repo_local(path, root)

      %Change{
        path: local_path,
        diff: diff
      }
    end)
  end

  # Warnings look like this:
  #
  #     warning: some warning message
  #     41 | some_code_here()
  #
  #     └─ path/name.ex: (file)
  @spec extract_warnings(String.t()) :: list(String.t())
  defp extract_warnings(output) do
    regex =
      ~r/
        warning:\s*(?<message>.*)\n
        (?<line>\d+)\s*\|\s*(?<code>.*)\s*\n*
        └─\s*(?<file>[^:]+):.*
      /x

    regex
    |> Regex.scan(output, capture: [:message, :line, :code, :file])
    |> Enum.map(fn [message, line, code, file] ->
      %Warning{
        message: message,
        line: String.to_integer(line),
        code: code,
        file: file
      }
    end)
  end

  # Converts absolute path to repository-local path
  # Example: /path/to/repos/elixir/lib/file.ex -> elixir/lib/file.ex
  @spec make_repo_local(String.t(), String.t()) :: String.t()
  defp make_repo_local(path, base_dir) do
    case String.split(path, base_dir, parts: 2) do
      [_, local_path] -> String.trim_leading(local_path, "/")
      _ -> path
    end
  end
end
