defmodule GreenValidation.CLI.Validate do
  @moduledoc """
  Command-line interface for the validation system.
  """

  alias GreenValidation.{
    BaselineFormatter,
    ClonedRepo,
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
  require Logger

  @program "mix green_validation.validate"

  @results_dir "results"

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
        Logger.info("Invalid command: #{inspect(reason)}")
        usage()
        halt(1)
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
    IO.puts("""
    Usage:
      #{HelpfulOptions.help_commands!(@program, @commands)}
    """)
  end

  defp check_all(switches) do
    case check_all_projects(switches) do
      {:ok, results} ->
        Logger.info("All projects validated successfully.")

        handle_format_output(results, switches)

      {:error, reason} ->
        Logger.info("Error during validation: #{reason}")
        halt(1)
    end
  end

  defp check_all_projects(switches) do
    {:ok, green_dependency} = GreenDependency.new(switches[:green])
    rules = Rules.all()

    opts = [
      green_dependency: green_dependency,
      verbose: switches[:verbose] || false,
      skip_existing: switches[:format] == "json"
    ]

    results =
      Enum.reduce_while(
        Projects.all(),
        [],
        fn project, acc ->
          Logger.info("Checking project: #{project.name}")

          case check_project_rules(project, rules, opts) do
            {:ok, :skipped} ->
              {:cont, acc}

            {:ok, results} ->
              {:cont, results ++ acc}

            {:error, reason} ->
              Logger.info("Validation failed for #{project.name}: #{reason}")
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
           green_dependency: green_dependency,
           verbose: switches[:verbose] || false
         ],
         {:ok, results} <- check_project_rules(project, rules, opts) do
      handle_format_output(results, switches)
    else
      {:error, reason} ->
        Logger.info("Error: #{reason}")
        halt(1)
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
          {:ok, [Result.t()] | :skipped} | {:error, String.t()}
  defp check_project_rules(project, rules, opts) do
    with {:ok, cloned_repo} <- Project.clone(project) do
      if skip_existing?(project, cloned_repo, opts) do
        Logger.info(
          "Skipping #{project.name}: JSON report already exists for commit #{cloned_repo.commit_sha}"
        )

        {:ok, :skipped}
      else
        validate_rules(cloned_repo, project, rules, opts)
      end
    end
  end

  @spec skip_existing?(Project.t(), ClonedRepo.t(), keyword) :: boolean
  defp skip_existing?(project, cloned_repo, opts) do
    Keyword.get(opts, :skip_existing, false) and
      ReportWriter.report_exists?(project.name, cloned_repo.commit_sha, :json,
        output_dir: @results_dir
      )
  end

  @spec validate_rules(ClonedRepo.t(), Project.t(), [atom], keyword) ::
          {:ok, [Result.t()]} | {:error, String.t()}
  defp validate_rules(cloned_repo, %Project{subprojects: []} = project, rules, opts) do
    with :ok <- Project.install_deps(project),
         :ok <- Project.compile(project),
         {:ok, baseline_status} <- BaselineFormatter.ensure_clean(project),
         {:ok, rule_results} <- RuleValidator.validate_rules(project, rules, opts),
         {:ok, test_run} <- build_test_run(project, cloned_repo, opts[:green_dependency]) do
      result = %Result{
        test_run: test_run,
        baseline: baseline_status,
        rules: rule_results
      }

      print_results(result, opts)
      {:ok, [result]}
    end
  end

  defp validate_rules(cloned_repo, %Project{subprojects: subprojects} = project, rules, opts) do
    import Access, only: [key: 1]

    # Treat each subproject as a separate project for validation purposes,
    # but reuse the same cloned repository
    subprojects
    |> Enum.map(fn subproject ->
      fake_project = %{
        project
        | path: subproject.path,
          mix_exs_add_dependency: subproject.mix_exs_add_dependency,
          subprojects: []
      }

      Logger.info("Running validation on #{subproject.path} subproject of #{project.name}")

      {:ok, [result]} = validate_rules(cloned_repo, fake_project, rules, opts)

      update_in(
        result,
        [key(:test_run), key(:project_name)],
        fn _existing -> "#{project.name} (#{subproject.path})" end
      )
    end)
    |> then(&{:ok, &1})
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

  defp print_results(%Result{} = result, opts) do
    verbose = Keyword.get(opts, :verbose, false)

    if result.baseline == :created_format_commit do
      IO.puts("Baseline formatting commit created for #{result.test_run.project_name}.")
    end

    Enum.each(
      result.rules,
      fn rule_result ->
        IO.puts("    Rule: #{rule_result.rule}")

        if length(rule_result.changes) == 0 and length(rule_result.warnings) == 0 do
          IO.puts("      ✅ No issues found.")
        end

        if length(rule_result.changes) > 0 do
          IO.puts("      🔧 Changes needed for #{length(rule_result.changes)} files:")

          Enum.each(rule_result.changes, fn change ->
            if verbose do
              IO.puts("        - #{change}")
            else
              IO.puts("        - #{change.path}")
            end
          end)
        end

        if length(rule_result.warnings) > 0 do
          IO.puts("      ⚠️ Warnings for #{length(rule_result.warnings)} files:")

          Enum.each(rule_result.warnings, fn warning ->
            if verbose do
              IO.puts("        - #{warning}")
            else
              IO.puts("        - #{warning.file}")
            end
          end)
        end
      end
    )
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
        Logger.info("Warning: Unknown format '#{other}'. Supported formats: 'json', 'text'")
        :ok
    end
  end

  defp write_report(result, format) do
    case ReportWriter.write(result, format, output_dir: @results_dir) do
      {:ok, filepath} ->
        Logger.info("\n📄 Report saved to: #{filepath}")
        :ok

      {:error, reason} ->
        Logger.info("\n⚠️  Warning: Failed to write report: #{inspect(reason)}")
        :ok
    end
  end

  defp halt(exit_code) do
    Logger.flush()
    System.halt(exit_code)
  end
end
