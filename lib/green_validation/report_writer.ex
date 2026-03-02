defmodule GreenValidation.ReportWriter do
  @moduledoc """
  Writes validation results to JSON or text files with timestamped filenames.
  """

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
  def write_text(result, filepath) do
    content = format_text(result)

    case File.write(filepath, content) do
      :ok -> {:ok, filepath}
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helpers

  defp format_json(result) do
    result
    |> encode_result()
    |> Jason.encode!(pretty: true)
  end

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

  defp format_baseline(:clean), do: "✅ Clean (no formatting needed)"
  defp format_baseline(:created_format_commit), do: "🔧 Created formatting commit"
  defp format_baseline(other), do: inspect(other)

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

  defp count_rules_with_changes(rules) do
    Enum.count(rules, fn r -> length(r.changes) > 0 end)
  end

  defp count_rules_with_warnings(rules) do
    Enum.count(rules, fn r -> length(r.warnings) > 0 end)
  end

  defp count_clean_rules(rules) do
    Enum.count(rules, fn r -> length(r.changes) == 0 and length(r.warnings) == 0 end)
  end

  defp generate_filename(result, format) do
    timestamp = format_timestamp(DateTime.utc_now())
    extension = if format == :json, do: "json", else: "txt"
    project_slug = String.replace(result.test_run.project_name, " ", "_")

    "validation_#{project_slug}_#{timestamp}.#{extension}"
  end

  defp format_timestamp(datetime) do
    datetime
    |> DateTime.to_iso8601(:basic)
    |> String.replace(~r/[Z\.\-\+:]/, "")
    |> String.slice(0, 15)
  end

  defp encode_result(result) do
    %{
      test_run: encode_test_run(result.test_run),
      baseline: result.baseline,
      rules: Enum.map(result.rules, &encode_rule_result/1)
    }
  end

  defp encode_test_run(test_run) do
    %{
      project_name: test_run.project_name,
      repository: test_run.repository,
      commit_sha: test_run.commit_sha,
      branch: test_run.branch,
      green_version: test_run.green_version
    }
  end

  defp encode_rule_result(rule_result) do
    %{
      rule: rule_result.rule,
      changes: rule_result.changes,
      warnings: rule_result.warnings
    }
  end
end
