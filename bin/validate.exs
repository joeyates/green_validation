#!/usr/bin/env elixir

# Main validation script for testing Green formatter against major Elixir projects

Mix.install([
  {:green_validation, path: __DIR__ |> Path.join("..") |> Path.expand()},
  {:helpful_options, "~> 0.4.4"},
  {:jason, "~> 1.4"}
])

defmodule GreenValidation.CLI do
  @moduledoc """
  Command-line interface for the validation system.
  """

  alias GreenValidation.{
    BaselineFormatter,
    GreenDependency,
    Projects,
    Project,
    ReportWriter,
    Result,
    Rules,
    RuleValidator,
    TestRun
  }

  require GreenValidation.Rules

  @program "bin/validate.exs"

  @common_switches [
    format: %{type: :string, description: "Output format for reports ('text' or 'json')"},
    green: %{
      type: :string,
      required: true,
      description:
        "Either a version tag (e.g. '0.1.0') or a path to a local checkout of the Green repository to use for validation"
    }
  ]

  @check_project_switches [
    rule: %{
      type: :string,
      description: "Specific rule to check (e.g. 'avoid_needless_pipelines')"
    },
    path: %{type: :string, description: "Path to a specific file to check with the rule"}
  ]

  @commands [
    %{commands: [], description: "Show this help message"},
    %{commands: ["help"], description: "Show this help message"},
    %{
      commands: ["check-all"],
      description: "Check all projects",
      switches: @common_switches
    },
    %{
      commands: ["check-project", :project_name],
      description: "Check a specific project",
      switches: @check_project_switches ++ @common_switches
    }
  ]

  def main(args) do
    case HelpfulOptions.parse_commands(args, @commands) do
      {:ok, parsed} ->
        run(parsed)

      {:error, reason} ->
        IO.puts("Invalid command: #{inspect(reason)}")
        usage()
        System.halt(1)
    end
  end

  defp run(%{commands: commands, switches: switches}) do
    case commands do
      [] ->
        usage()

      ["help"] ->
        usage()

      ["check-all"] ->
        check_all(switches)

      ["check-project", project_name] ->
        check_project(project_name, switches)
    end
  end

  defp usage() do
    IO.puts("Usage:\n")
    IO.puts(HelpfulOptions.help_commands!(@program, @commands))
  end

  defp check_all(switches) do
    case check_all_projects(switches) do
      {:ok, results} ->
        IO.puts("All projects validated successfully.")

        handle_format_output(results, switches)

      {:error, reason} ->
        IO.puts("Error during validation: #{reason}")
        System.halt(1)
    end
  end

  defp check_all_projects(switches) do
    {:ok, green_dependency} = GreenDependency.new(switches[:green])
    rules = Rules.all()
    opts = [green_dependency: green_dependency]

    results =
      Enum.reduce_while(
        Projects.all(),
        [],
        fn project, acc ->
          IO.puts("Checking project: #{project.name}")

          case check_project_rules(project, rules, opts) do
            {:ok, results} ->
              {:cont, results ++ acc}

            {:error, reason} ->
              IO.puts("Validation failed for #{project.name}: #{reason}")
              {:halt, {:error, reason}}
          end
        end
      )

    case results do
      {:error, _} = error -> error
      results -> {:ok, Enum.reverse(results)}
    end
  end

  defp check_project(project_name, switches) do
    project = Projects.load!(project_name)

    with {:ok, green_dependency} = GreenDependency.new(switches[:green]),
         {:ok, rules} = prepare_rules(switches[:rule]),
         opts = [
           file_path: switches[:path],
           green_dependency: green_dependency
         ],
         {:ok, results} <- check_project_rules(project, rules, opts) do
      handle_format_output(results, switches)
    else
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        System.halt(1)
    end
  end

  defp prepare_rules(rule_name) do
    if rule_name do
      rule_atom = String.to_atom(rule_name)

      if rule_atom in Rules.all() do
        {:ok, [rule_atom]}
      else
        {:error, "Unknown rule '#{rule_name}'. Available rules: #{Enum.join(Rules.all(), ", ")}"}
      end
    else
      {:ok, Rules.all()}
    end
  end

  @spec check_project_rules(Project.t(), [atom], keyword) ::
          {:ok, [Result.t()]} | {:error, String.t()}
  defp check_project_rules(project, rules, opts) do
    with {:ok, cloned_repo} <- Project.clone(project),
         {:ok, baseline_status} <- BaselineFormatter.ensure_clean(project),
         {:ok, rule_results} <- RuleValidator.validate_rules(project, rules, opts),
         {:ok, test_run} <- build_test_run(project, cloned_repo, opts[:green_dependency]) do
      result = %Result{
        test_run: test_run,
        baseline: baseline_status,
        rules: rule_results
      }

      # Print output for backwards compatibility
      if baseline_status == :created_format_commit do
        IO.puts("Baseline formatting commit created for #{project.name}.")
      end

      Enum.each(
        rule_results,
        fn rule_result ->
          IO.puts("    Rule: #{rule_result.rule}")

          if length(rule_result.changes) == 0 and length(rule_result.warnings) == 0 do
            IO.puts("      ✅ No issues found.")
          end

          if length(rule_result.changes) > 0 do
            IO.puts("      🔧 Changes needed for #{length(rule_result.changes)} files:")
            Enum.each(rule_result.changes, &IO.puts("        - #{&1}"))
          end

          if length(rule_result.warnings) > 0 do
            IO.puts("      ⚠️ Warnings for #{length(rule_result.warnings)} files:")
            Enum.each(rule_result.warnings, &IO.puts("        - #{&1}"))
          end
        end
      )

      {:ok, [result]}
    end
  end

  @spec build_test_run(Project.t(), ClonedRepo.t(), GreenDependency.t()) ::
          {:ok, TestRun.t()} | {:error, String.t()}
  defp build_test_run(project, cloned_repo, green_dependency) do
    with {:ok, green_version} <- GreenDependency.get_version(green_dependency) do
      test_run = %TestRun{
        project_name: project.name,
        repository: cloned_repo.project.url,
        commit_sha: cloned_repo.commit_sha,
        branch: cloned_repo.branch,
        green_version: green_version
      }

      {:ok, test_run}
    end
  end

  defp handle_format_output(results, switches) do
    case switches[:format] do
      nil ->
        # No format specified, do nothing (already printed to stdout)
        :ok

      format_string when format_string in ["json", "text"] ->
        format = String.to_atom(format_string)

        Enum.each(results, fn result ->
          write_report(result, format)
        end)

      other ->
        IO.puts("Warning: Unknown format '#{other}'. Supported formats: 'json', 'text'")
        :ok
    end
  end

  defp write_report(result, format) do
    output_dir = "results"

    case ReportWriter.write(result, format, output_dir: output_dir) do
      {:ok, filepath} ->
        IO.puts("\n📄 Report saved to: #{filepath}")
        :ok

      {:error, reason} ->
        IO.puts("\n⚠️  Warning: Failed to write report: #{inspect(reason)}")
        :ok
    end
  end
end

GreenValidation.CLI.main(System.argv())
