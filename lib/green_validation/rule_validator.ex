defmodule GreenValidation.RuleValidator do
  @moduledoc """
  Validates Green rules individually against target projects.

  For each rule, creates a custom .formatter.exs that disables all other rules,
  then runs mix format --check-formatted to identify affected files.
  """

  alias GreenValidation.{GreenInstaller, OutputParser, Project, RuleResult}
  alias GreenValidation.Installer.{FormatterExs, MixExs}

  @doc """
  List of all configurable Green rules.

  These keys correspond to the snake_case names used in .formatter.exs configuration.
  """
  @spec all_rules() :: list(atom())
  def all_rules do
    [
      :avoid_needless_pipelines,
      :no_anonymous_functions_in_pipelines,
      :no_unless_with_else,
      :no_nil_else,
      :true_in_cond,
      :boolean_operators,
      :use_string_concatenation_when_matching_binaries,
      :avoid_one_letter_variables,
      :predicate_functions,
      :upper_camel_case_for_modules,
      :sort_module_references,
      :use_module_pseudo_variable,
      :remove_nil_from_struct_definition,
      :use_error_suffix,
      :lowercase_exception_messages,
      :no_trailing_punctuation_in_exception_messages,
      :prefer_pipelines,
      :avoid_caps,
      :use_parentheses_with_zero_arity_functions
    ]
    |> Enum.uniq()
  end

  @doc """
  Validates all rules for a given target (can be a subproject).

  ## Parameters
  - `project_dir` - The directory of the project to validate

  ## Returns
  A `TestResult` struct containing the results of validating each rule.

  """
  @spec validate_rules(
          Project.t(),
          [atom],
          keyword
        ) ::
          {:ok, list(RuleResult.t())} | {:error, map()}
  def validate_rules(%Project{} = project, rules, opts) do
    IO.puts("  Validating #{length(rules)} rules individually...")

    green_dependency = Keyword.fetch!(opts, :green_dependency)
    :ok = GreenInstaller.install_green(project, green_version: green_dependency)

    Enum.reduce(
      rules,
      {:ok, []},
      fn
        rule, {:ok, acc} ->
          IO.write("    #{rule}... ")

          case validate_single_rule(project, rule, opts) do
            {:ok, result} ->
              IO.puts("OK")
              {:ok, [result | acc]}

            {:error, reason} ->
              IO.puts("ERROR: #{reason}")
              {:error, %{rule: rule, error: reason}}
          end

        _rule, {:error, _} = error ->
          error
      end
    )
  after
    :ok = MixExs.reset(project)
  end

  @spec validate_single_rule(Project.t(), atom, keyword) ::
          {:ok, RuleResult.t()} | {:error, String.t()}
  defp validate_single_rule(%Project{} = project, rule, opts) do
    rules = project_rule_config(project, rule)
    file_path = Keyword.get(opts, :file_path)
    :ok = GreenInstaller.prepare_formatter_exs(project, rules)
    project_path = Project.path(project)
    environment = Project.environment(project)

    params =
      if file_path do
        ["format", "--check-formatted", file_path]
      else
        ["format", "--check-formatted"]
      end

    {output, exit_code} =
      System.cmd(
        "mix",
        params,
        cd: project_path,
        env: environment,
        stderr_to_stdout: true
      )

    parse_format_output(project, rule, output, exit_code)
  after
    :ok = FormatterExs.reset(project)
  end

  @spec project_rule_config(Project.t(), atom()) :: list({atom(), keyword()})
  defp project_rule_config(%Project{} = project, enabled_rule) do
    generic_config = generate_config(enabled_rule)
    Project.rule_config(project, enabled_rule, generic_config)
  end

  @spec generate_config(atom()) :: list({atom(), keyword()})
  defp generate_config(enabled_rule) do
    all_rules()
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
