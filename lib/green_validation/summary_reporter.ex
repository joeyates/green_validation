defmodule GreenValidation.SummaryReporter do
  @moduledoc """
  Generates aggregate summary reports from multiple validation results.

  This module can:
  - Load all JSON results from the results directory
  - Calculate aggregate statistics across all projects
  - Generate per-project summaries
  - Identify most commonly triggered rules
  - Calculate overall compliance rates
  """

  @doc """
  Loads all JSON result files from the results directory.

  ## Parameters
  - `results_dir` - Path to the results directory

  ## Returns
  List of parsed result maps
  """
  def load_all_results(results_dir) do
    results_dir
    |> Path.join("*.json")
    |> Path.wildcard()
    |> Enum.map(&load_result_file/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Loads a single JSON result file.

  Returns the parsed result map or nil if loading fails.
  """
  def load_result_file(filepath) do
    case File.read(filepath) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, result} ->
            atomize_keys(result)

          {:error, reason} ->
            IO.puts("Warning: Failed to parse #{filepath}: #{inspect(reason)}")
            nil
        end

      {:error, reason} ->
        IO.puts("Warning: Failed to read #{filepath}: #{inspect(reason)}")
        nil
    end
  end

  @doc """
  Generates a comprehensive summary report from all results.

  ## Returns
  A map containing:
  - `:total_projects` - Number of projects validated
  - `:total_targets` - Number of validation targets (including subprojects)
  - `:baseline_clean_count` - Number of targets with clean baseline
  - `:all_rules` - Set of all rules tested
  - `:rule_statistics` - Per-rule statistics across all projects
  - `:project_summaries` - Per-project summary information
  """
  def generate_summary(results) do
    %{
      total_projects: count_unique_projects(results),
      total_targets: length(results),
      baseline_clean_count: count_clean_baselines(results),
      all_rules: collect_all_rules(results),
      rule_statistics: calculate_rule_statistics(results),
      project_summaries: generate_project_summaries(results)
    }
  end

  @doc """
  Prints a human-readable summary report to the console.
  """
  def print_summary(summary) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("VALIDATION SUMMARY REPORT")
    IO.puts(String.duplicate("=", 80))

    print_overview(summary)
    print_baseline_statistics(summary)
    print_rule_statistics(summary)
    print_project_summaries(summary)

    IO.puts(String.duplicate("=", 80))
  end

  @doc """
  Generates and prints a summary report from the results directory.

  ## Parameters
  - `results_dir` - Path to the results directory
  """
  def generate_and_print_summary(results_dir) do
    results = load_all_results(results_dir)

    if Enum.empty?(results) do
      IO.puts("No validation results found in #{results_dir}")
    else
      summary = generate_summary(results)
      print_summary(summary)
      summary
    end
  end

  # Count unique projects (excluding subproject suffixes)
  defp count_unique_projects(results) do
    results
    |> Enum.map(fn r -> get_in(r, [:metadata, :project]) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&extract_base_project_name/1)
    |> Enum.uniq()
    |> length()
  end

  # Extract base project name (e.g., "elixir_lib_elixir" -> "elixir")
  defp extract_base_project_name(project_name) when is_binary(project_name) do
    project_name
    |> String.split("_")
    |> List.first()
  end

  defp extract_base_project_name(_), do: "unknown"

  # Count how many targets have clean baselines
  defp count_clean_baselines(results) do
    Enum.count(results, fn r ->
      get_in(r, [:baseline, :clean]) == true
    end)
  end

  # Collect all unique rules across all results
  defp collect_all_rules(results) do
    results
    |> Enum.flat_map(fn r -> get_in(r, [:rules]) || [] end)
    |> Enum.map(fn rule -> rule[:rule] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  # Calculate statistics for each rule across all projects
  defp calculate_rule_statistics(results) do
    all_rules = collect_all_rules(results)

    Enum.map(all_rules, fn rule_name ->
      stats =
        results
        |> Enum.flat_map(fn r -> get_in(r, [:rules]) || [] end)
        |> Enum.filter(fn rule -> rule[:rule] == rule_name end)
        |> aggregate_rule_stats()

      Map.put(stats, :rule, rule_name)
    end)
    |> Enum.sort_by(& &1.total_files_affected, :desc)
  end

  # Aggregate statistics for a single rule across multiple results
  defp aggregate_rule_stats(rule_occurrences) do
    total_files = Enum.sum(Enum.map(rule_occurrences, &(&1[:files_affected] || 0)))
    total_changes = Enum.sum(Enum.map(rule_occurrences, &(&1[:total_changes] || 0)))
    projects_affected = Enum.count(rule_occurrences, &(&1[:files_affected] > 0))

    %{
      total_files_affected: total_files,
      total_changes: total_changes,
      projects_affected: projects_affected,
      total_projects_tested: length(rule_occurrences)
    }
  end

  # Generate per-project summaries
  defp generate_project_summaries(results) do
    results
    |> Enum.map(fn result ->
      metadata = result[:metadata] || %{}
      baseline = result[:baseline] || %{}
      rules = result[:rules] || []

      triggered_rules = Enum.count(rules, &(&1[:files_affected] > 0))

      %{
        project: metadata[:project],
        target_name: metadata[:target_name],
        baseline_clean: baseline[:clean] || false,
        rules_triggered: triggered_rules,
        total_rules: length(rules),
        validated_at: metadata[:validated_at]
      }
    end)
    |> Enum.sort_by(& &1.project)
  end

  # Print overview section
  defp print_overview(summary) do
    IO.puts("\nOVERVIEW")
    IO.puts(String.duplicate("-", 80))
    IO.puts("Total Projects:        #{summary.total_projects}")
    IO.puts("Total Targets:         #{summary.total_targets}")
    IO.puts("Unique Rules Tested:   #{length(summary.all_rules)}")
  end

  # Print baseline statistics
  defp print_baseline_statistics(summary) do
    clean_count = summary.baseline_clean_count
    total = summary.total_targets
    percentage = if total > 0, do: Float.round(clean_count / total * 100, 1), else: 0

    IO.puts("\nBASELINE FORMATTING")
    IO.puts(String.duplicate("-", 80))
    IO.puts("Clean (already formatted):  #{clean_count}/#{total} (#{percentage}%)")
    IO.puts("Need formatting:            #{total - clean_count}/#{total}")
  end

  # Print rule statistics
  defp print_rule_statistics(summary) do
    IO.puts("\nRULE STATISTICS")
    IO.puts(String.duplicate("-", 80))
    IO.puts("Top 10 Most Triggered Rules:")
    IO.puts("")

    IO.puts(
      String.pad_trailing("Rule", 50) <>
        String.pad_leading("Projects", 12) <>
        String.pad_leading("Files", 10) <>
        String.pad_leading("Changes", 10)
    )

    IO.puts(String.duplicate("-", 80))

    summary.rule_statistics
    |> Enum.take(10)
    |> Enum.each(fn stat ->
      rule_name = String.slice(to_string(stat.rule), 0, 48)

      IO.puts(
        String.pad_trailing(rule_name, 50) <>
          String.pad_leading("#{stat.projects_affected}", 12) <>
          String.pad_leading("#{stat.total_files_affected}", 10) <>
          String.pad_leading("#{stat.total_changes}", 10)
      )
    end)

    # Rules with no triggers
    untriggered = Enum.count(summary.rule_statistics, &(&1.total_files_affected == 0))

    if untriggered > 0 do
      IO.puts("\nRules never triggered: #{untriggered}")
    end
  end

  # Print per-project summaries
  defp print_project_summaries(summary) do
    IO.puts("\nPER-PROJECT RESULTS")
    IO.puts(String.duplicate("-", 80))

    IO.puts(
      String.pad_trailing("Project", 40) <>
        String.pad_leading("Baseline", 12) <>
        String.pad_leading("Rules", 12)
    )

    IO.puts(String.duplicate("-", 80))

    summary.project_summaries
    |> Enum.each(fn proj ->
      project_name = String.slice(to_string(proj.project), 0, 38)
      baseline_status = if proj.baseline_clean, do: "✓ clean", else: "✗ dirty"
      rules_info = "#{proj.rules_triggered}/#{proj.total_rules}"

      IO.puts(
        String.pad_trailing(project_name, 40) <>
          String.pad_leading(baseline_status, 12) <>
          String.pad_leading(rules_info, 12)
      )
    end)
  end

  # Recursively convert string keys to atoms
  defp atomize_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {atomize_key(k), atomize_keys(v)} end)
    |> Enum.into(%{})
  end

  defp atomize_keys(list) when is_list(list) do
    Enum.map(list, &atomize_keys/1)
  end

  defp atomize_keys(value), do: value

  defp atomize_key(key) when is_binary(key) do
    String.to_atom(key)
  end

  defp atomize_key(key), do: key
end
