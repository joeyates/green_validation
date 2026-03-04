defmodule GreenValidation.RuleValidator do
  @moduledoc """
  Validates Green rules individually against target projects.

  For each rule, creates a custom .formatter.exs that disables all other rules,
  then runs mix format --check-formatted to identify affected files.
  """

  alias GreenValidation.{GreenInstaller, OutputParser, Project, RuleResult}
  alias GreenValidation.Installer.MixExs

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
  @spec validate_all_rules(Project.t(), {:green, String.t()} | {:green, String.t(), path: String.t()}) ::
          {:ok, list(RuleResult.t())} | {:error, map()}
  def validate_all_rules(%Project{} = project, green_dependency) do
    IO.puts("  Validating #{length(all_rules())} rules individually...")

    GreenInstaller.install_green(project, green_version: green_dependency)

    Enum.reduce(
      all_rules(),
      {:ok, []},
      fn
        rule, {:ok, acc} ->
          IO.write("    #{rule}... ")

          case validate_single_rule(project, rule) do
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
    :ok = MixExs.reset_mix_exs(project)
  end

  @spec validate_single_rule(Project.t(), atom) :: {:ok, RuleResult.t()} | {:error, String.t()}
  defp validate_single_rule(%Project{} = project, rule) do
    rules =
      rule
      |> generate_config()
      |> then(&Project.rule_config(project, rule, &1))

    :ok = GreenInstaller.prepare_formatter_exs(project, rules)
    project_path = Project.path(project)
    environment = Project.environment(project)

    {output, exit_code} =
      System.cmd(
        "mix",
        ["format", "--check-formatted"],
        cd: project_path,
        env: environment,
        stderr_to_stdout: true
      )

    parse_format_output(project, rule, output, exit_code)
  after
    :ok = GreenInstaller.reset_formatter_exs(project)
  end

  @doc """
  Generates a list of rules to **disable** all rules except the specified one.
  """
  @spec generate_config(atom()) :: list({atom(), keyword()})
  def generate_config(enabled_rule) do
    all_rules()
    |> Enum.reject(&(&1 == enabled_rule))
    |> Enum.map(fn rule -> {rule, [enabled: false]} end)
  end

  @doc """
  Parses the output from `mix format --check-formatted`.

  Uses OutputParser to extract file paths and affected line numbers.

  ## Returns
  - `{:ok, %RuleResult{}}` on success
  - `{:error, reason}` on failure
  """
  @spec parse_format_output(Project.t(), atom(), String.t(), non_neg_integer()) ::
          {:ok, RuleResult.t()} | {:error, String.t()}
  def parse_format_output(project, rule, output, exit_code) do
    {:ok, repo} = Project.repo(project)

    cond do
      output == "" ->
        {:ok, %RuleResult{rule: rule}}

      exit_code in [0, 1] ->
        OutputParser.parse_output(repo, rule, output)

      true ->
        # Error occurred
        {:error, "mix format failed with exit code #{exit_code}: #{output}"}
    end
  end
end
