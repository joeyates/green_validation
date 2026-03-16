defmodule GreenValidation.RuleValidator do
  @moduledoc """
  Validates Green rules individually against target projects.

  For each rule, creates a custom .formatter.exs that disables all other rules,
  then runs mix format --check-formatted to identify affected files.
  """

  alias GreenValidation.{GreenInstaller, OutputParser, Project, RuleResult, Rules}
  alias GreenValidation.Installer.{FormatterExs, MixExs}

  require Logger

  @doc """
  Validates all rules for a given target (can be a subproject).

  ## Parameters
  - `project_dir` - The directory of the project to validate

  ## Returns
  A `TestResult` struct containing the results of validating each rule.

  """
  @spec validate_rules(Project.t(), [atom], keyword) ::
          {:ok, list(RuleResult.t())} | {:error, map()}
  def validate_rules(%Project{} = project, rules, opts) do
    Logger.info("  Validating #{length(rules)} rules individually...")

    green_dependency = Keyword.fetch!(opts, :green_dependency)
    mix_exs_action = GreenInstaller.install_green(project, green_version: green_dependency)

    try do
      Enum.reduce(
        rules,
        {:ok, []},
        fn
          rule, {:ok, acc} ->
            Logger.info("#{rule}...")

            case validate_single_rule(project, rule, opts) do
              {:ok, result} ->
                {:ok, [result | acc]}

              {:error, reason} ->
                Logger.info("ERROR: #{reason}")
                Logger.flush()
                {:error, %{rule: rule, error: reason}}
            end

          _rule, {:error, _} = error ->
            error
        end
      )
    after
      :ok = MixExs.reset(project, mix_exs_action)
    end
  end

  @spec validate_single_rule(Project.t(), atom, keyword) ::
          {:ok, RuleResult.t()} | {:error, String.t()}
  defp validate_single_rule(%Project{} = project, rule, opts) do
    rules = project_rule_config(project, rule)
    file_path = Keyword.get(opts, :file_path)
    {:ok, formatter_setup_action} = GreenInstaller.prepare_formatter_exs(project, rules)

    try do
      command =
        if file_path do
          "format --check-formatted #{file_path}"
        else
          "format --check-formatted"
        end

      {output, exit_code} = Project.mix_command(project, command)

      parse_format_output(project, rule, output, exit_code)
    after
      :ok = FormatterExs.reset(project, formatter_setup_action)
    end
  end

  @spec project_rule_config(Project.t(), atom()) :: list({atom(), keyword()})
  defp project_rule_config(%Project{} = project, enabled_rule) do
    generic_config = generate_config(enabled_rule)
    Project.rule_config(project, enabled_rule, generic_config)
  end

  @spec generate_config(atom()) :: list({atom(), keyword()})
  defp generate_config(enabled_rule) do
    Rules.all()
    |> Enum.reject(&(&1 == enabled_rule))
    |> Enum.map(fn rule -> {rule, [enabled: false]} end)
  end

  @spec parse_format_output(Project.t(), atom(), String.t(), non_neg_integer()) ::
          {:ok, RuleResult.t()} | {:error, String.t()}
  defp parse_format_output(project, rule, output, exit_code) do
    cond do
      output == "" ->
        {:ok, %RuleResult{rule: rule}}

      exit_code in [0, 1] ->
        OutputParser.parse_output(project, rule, output)

      true ->
        {:error, "mix format failed with exit code #{exit_code}: #{output}"}
    end
  end
end
