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
    Projects,
    Project,
    ReportWriter,
    Result,
    RuleValidator,
    TestRun
  }

  require GreenValidation.RuleValidator

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
      switches: @common_switches
    },
    %{
      commands: ["check-project-rule", :project_name, :rule_name],
      description: "Check a single rule for a specific project",
      switches: @common_switches
    }
  ]

  def main(args) do
    with {:ok, parsed} <- HelpfulOptions.parse_commands(args, @commands),
         {:ok, green_dependency} <- parse_green_dependency(parsed.switches[:green]) do
      run(parsed, green_dependency)
    else
      {:error, reason} ->
        IO.puts("Invalid command: #{inspect(reason)}")
        usage()
        System.halt(1)
    end
  end

  defp run(%{commands: commands, switches: switches}, green_dependency) do
    case commands do
      [] ->
        usage()

      ["help"] ->
        usage()

      ["check-all"] ->
        check_all(switches, green_dependency)

      ["check-project", project_name] ->
        check_project(project_name, switches, green_dependency)

      ["check-project-rule", project_name, rule_name] ->
        check_project_rule(project_name, rule_name, switches, green_dependency)
    end
  end

  defp usage() do
    IO.puts("Usage:\n")
    IO.puts(HelpfulOptions.help_commands!(@program, @commands))
  end

  defp check_all(switches, green_dependency) do
    case check_all_projects(green_dependency) do
      {:ok, results} ->
        IO.puts("All projects validated successfully.")

        # Write report if format is specified
        handle_format_output(results, switches, "all")
        :ok

      {:error, reason} ->
        IO.puts("Error during validation: #{reason}")
        System.halt(1)
    end
  end

  defp check_all_projects(green_dependency) do
    rules = RuleValidator.all_rules()

    results =
      Enum.reduce_while(
        Projects.all(),
        [],
        fn project, acc ->
          IO.puts("Checking project: #{project.name}")

          case check_project_rules(project, rules, green_dependency) do
            {:ok, result} ->
              {:cont, [result | acc]}

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

  defp check_project(project_name, switches, green_dependency) do
    project = Projects.load!(project_name)
    rules = RuleValidator.all_rules()

    with {:ok, result} <- check_project_rules(project, rules, green_dependency) do
      handle_format_output(result, switches, project_name)
    else
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        System.halt(1)
    end
  end

  def check_project_rule(project_name, rule_name, switches, green_dependency) do
    project = Projects.load!(project_name)
    rule_atom = String.to_atom(rule_name)

    if rule_atom not in RuleValidator.all_rules() do
      IO.puts(
        "Error: Unknown rule '#{rule_name}'. Available rules: #{Enum.join(RuleValidator.all_rules(), ", ")}"
      )

      System.halt(1)
    end

    with {:ok, result} <- check_project_rules(project, [rule_atom], green_dependency) do
      handle_format_output(result, switches, "#{project_name}-#{rule_name}")
    else
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        System.halt(1)
    end
  end

  @spec check_project_rules(
          Project.t(),
          [atom],
          {:green, String.t()} | {:green, String.t(), path: String.t()}
        ) ::
          {:ok, Result.t()} | {:error, String.t()}
  defp check_project_rules(project, rules, green_dependency) do
    with {:ok, cloned_repo} <- Project.clone(project),
         {:ok, baseline_status} <- BaselineFormatter.ensure_clean(project),
         {:ok, rule_results} <- RuleValidator.validate_rules(project, rules, green_dependency),
         {:ok, test_run} <- build_test_run(project, cloned_repo, green_dependency) do
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

      {:ok, result}
    end
  end

  @spec build_test_run(
          Project.t(),
          ClonedRepo.t(),
          {:green, String.t()} | {:green, String.t(), path: String.t()}
        ) :: {:ok, TestRun.t()} | {:error, String.t()}
  defp build_test_run(project, cloned_repo, green_dependency) do
    with {:ok, green_version} <- get_green_version(green_dependency) do
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

  defp parse_green_dependency(green_arg) do
    cond do
      Regex.match?(~r"\d+\.\d+\.\d+$", green_arg) ->
        {:ok, {:green, green_arg}}

      File.dir?(green_arg) ->
        green_path = Path.expand(green_arg)
        {:ok, {:green, ">= 0.0.0", path: green_path}}

      true ->
        {:error,
         "Invalid --green argument. Must be a version tag (e.g. '0.1.0') or a path to a local checkout of the Green repository."}
    end
  end

  defp get_green_version({:green, version}) when is_binary(version), do: {:ok, version}

  defp get_green_version({:green, _version, path: local_path}) do
    case System.cmd("git", ["rev-parse", "HEAD"],
           cd: local_path,
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, String.trim(output)}
      {output, _} -> {:error, "Failed to get green SHA: #{output}"}
    end
  end

  defp handle_format_output(result_or_results, switches, project_identifier) do
    case switches[:format] do
      nil ->
        # No format specified, do nothing (already printed to stdout)
        :ok

      format_string when format_string in ["json", "text"] ->
        format = String.to_atom(format_string)

        case result_or_results do
          # Single result
          %Result{} = result ->
            write_report(result, format, project_identifier)

          # List of results (from check_all)
          results when is_list(results) ->
            Enum.each(results, fn result ->
              project_name = result.test_run.project_name
              write_report(result, format, project_name)
            end)
        end

      other ->
        IO.puts("Warning: Unknown format '#{other}'. Supported formats: 'json', 'text'")
        :ok
    end
  end

  defp write_report(result, format, _project_identifier) do
    # Save reports in the results directory
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
