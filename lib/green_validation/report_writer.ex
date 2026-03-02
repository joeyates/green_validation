defmodule GreenValidation.ReportWriter do
  @moduledoc """
  Writes validation results to JSON or text files with timestamped filenames.
  """

  alias GreenValidation.{Result, RuleResult, TestRun}

  @doc """
  Writes validation results to a file in the specified format.

  ## Parameters
  - `result` - The validation Result struct to write
  - `format` - Either `:json` or `:text`
  - `opts` - Options including:
    - `:output_dir` - Directory to write the file (default: current directory)
    - `:filename` - Custom filename (default: auto-generated with timestamp)

  ## Returns
  - `{:ok, filepath}` - Path to the written file
  - `{:error, reason}` - Error details
  """
  @spec write(Result.t(), :json | :text, keyword()) :: {:ok, String.t()} | {:error, term()}
  def write(result, format, opts \\ []) when format in [:json, :text] do
    output_dir = Keyword.get(opts, :output_dir, ".")
    filename = Keyword.get(opts, :filename, generate_filename(result, format))
    filepath = Path.join(output_dir, filename)

    File.mkdir_p!(output_dir)

    content =
      case format do
        :json -> format_json(result)
        :text -> format_text(result)
      end

    case File.write(filepath, content) do
      :ok -> {:ok, filepath}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Writes validation results as JSON.

  ## Parameters
  - `result` - The validation Result struct
  - `filepath` - Path where the file should be written

  ## Returns
  - `{:ok, filepath}` - Path to the written file
  - `{:error, reason}` - Error details
  """
  @spec write_json(Result.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def write_json(result, filepath) do
    content = format_json(result)

    case File.write(filepath, content) do
      :ok -> {:ok, filepath}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Writes validation results as formatted text.

  ## Parameters
  - `result` - The validation Result struct
  - `filepath` - Path where the file should be written

  ## Returns
  - `{:ok, filepath}` - Path to the written file
  - `{:error, reason}` - Error details
  """
  @spec write_text(Result.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def write_text(result, filepath) do
    content = format_text(result)

    case File.write(filepath, content) do
      :ok -> {:ok, filepath}
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helpers

  @spec format_json(Result.t()) :: String.t()
  defp format_json(result) do
    result
    |> encode_result()
    |> Jason.encode!(pretty: true)
  end

  @spec format_text(Result.t()) :: String.t()
  defp format_text(result) do
    lines = [
      "=" |> String.duplicate(80),
      "VALIDATION REPORT",
      "=" |> String.duplicate(80),
      "",
      "Project: #{result.test_run.project_name}",
      "Repository: #{result.test_run.repository}",
      "Commit: #{result.test_run.commit_sha}",
      "Branch: #{result.test_run.branch}",
      "Green Version: #{result.test_run.green_version}",
      "",
      "Baseline Status: #{format_baseline(result.baseline)}",
      "",
      "-" |> String.duplicate(80),
      "RULE VALIDATION RESULTS",
      "-" |> String.duplicate(80),
      ""
    ]

    rule_lines =
      Enum.flat_map(result.rules, fn rule_result ->
        [
          "Rule: #{rule_result.rule}",
          format_rule_result(rule_result),
          ""
        ]
      end)

    summary_lines = [
      "-" |> String.duplicate(80),
      "SUMMARY",
      "-" |> String.duplicate(80),
      "",
      "Total Rules Tested: #{length(result.rules)}",
      "Rules with Changes: #{count_rules_with_changes(result.rules)}",
      "Rules with Warnings: #{count_rules_with_warnings(result.rules)}",
      "Rules with No Issues: #{count_clean_rules(result.rules)}",
      "",
      "=" |> String.duplicate(80)
    ]

    (lines ++ rule_lines ++ summary_lines)
    |> Enum.join("\n")
  end

  @spec format_baseline(:clean | :created_format_commit | term()) :: String.t()
  defp format_baseline(:clean), do: "✅ Clean (no formatting needed)"
  defp format_baseline(:created_format_commit), do: "🔧 Created formatting commit"
  defp format_baseline(other), do: inspect(other)

  @spec format_rule_result(RuleResult.t()) :: String.t()
  defp format_rule_result(rule_result) do
    cond do
      length(rule_result.changes) == 0 and length(rule_result.warnings) == 0 ->
        "  ✅ No issues found."

      length(rule_result.changes) > 0 and length(rule_result.warnings) == 0 ->
        changes_text =
          Enum.map(rule_result.changes, &"    - #{&1}")
          |> Enum.join("\n")

        "  🔧 Changes needed for #{length(rule_result.changes)} files:\n#{changes_text}"

      length(rule_result.changes) == 0 and length(rule_result.warnings) > 0 ->
        warnings_text =
          Enum.map(rule_result.warnings, &"    - #{&1}")
          |> Enum.join("\n")

        "  ⚠️  Warnings for #{length(rule_result.warnings)} files:\n#{warnings_text}"

      true ->
        changes_text =
          Enum.map(rule_result.changes, &"    - #{&1}")
          |> Enum.join("\n")

        warnings_text =
          Enum.map(rule_result.warnings, &"    - #{&1}")
          |> Enum.join("\n")

        "  🔧 Changes needed for #{length(rule_result.changes)} files:\n#{changes_text}\n  ⚠️  Warnings for #{length(rule_result.warnings)} files:\n#{warnings_text}"
    end
  end

  @spec count_rules_with_changes(list(RuleResult.t())) :: non_neg_integer()
  defp count_rules_with_changes(rules) do
    Enum.count(rules, fn r -> length(r.changes) > 0 end)
  end

  @spec count_rules_with_warnings(list(RuleResult.t())) :: non_neg_integer()
  defp count_rules_with_warnings(rules) do
    Enum.count(rules, fn r -> length(r.warnings) > 0 end)
  end

  @spec count_clean_rules(list(RuleResult.t())) :: non_neg_integer()
  defp count_clean_rules(rules) do
    Enum.count(rules, fn r -> length(r.changes) == 0 and length(r.warnings) == 0 end)
  end

  @spec generate_filename(Result.t(), :json | :text) :: String.t()
  defp generate_filename(result, format) do
    # Use commit SHA instead of timestamp for filename
    commit_sha = result.test_run.commit_sha
    # Take first 8 characters of commit SHA
    short_sha = String.slice(commit_sha, 0, 8)
    extension = if format == :json, do: "json", else: "txt"
    project_slug = String.replace(result.test_run.project_name, " ", "_")

    "validation_#{project_slug}_#{short_sha}.#{extension}"
  end

  @spec encode_result(Result.t()) :: map()
  defp encode_result(result) do
    # Filter out rules with no changes or warnings for JSON output
    filtered_rules =
      result.rules
      |> Enum.reject(fn rule ->
        length(rule.changes) == 0 and length(rule.warnings) == 0
      end)
      |> Enum.map(&encode_rule_result/1)

    %{
      test_run: encode_test_run(result.test_run),
      baseline: result.baseline,
      rules: filtered_rules
    }
  end

  @spec encode_test_run(TestRun.t()) :: map()
  defp encode_test_run(test_run) do
    %{
      project_name: test_run.project_name,
      repository: test_run.repository,
      commit_sha: test_run.commit_sha,
      branch: test_run.branch,
      green_version: test_run.green_version
    }
  end

  @spec encode_rule_result(RuleResult.t()) :: map()
  defp encode_rule_result(rule_result) do
    %{
      rule: rule_result.rule,
      changes: rule_result.changes,
      warnings: rule_result.warnings
    }
  end
end
