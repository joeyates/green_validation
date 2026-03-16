defmodule GreenValidation.BaselineFormatter do
  @moduledoc """
  Performs baseline formatting checks on projects without Green formatter.
  """

  alias GreenValidation.Project
  alias GreenValidation.Installer.{FormatterExs, MixExs}

  require Logger

  @doc """
  Checks if a project is already formatted according to Elixir's standard formatter.

  If not, commits the necessary changes to create a baseline for Green formatter to compare against.
  """
  @spec ensure_clean(Project.t()) ::
          {:ok, :clean | :created_format_commit} | {:error, String.t()}
  def ensure_clean(%Project{} = project) do
    Logger.info("  Checking baseline formatting")
    mix_exs_action = MixExs.ensure_mix_exs(project)
    {:ok, formatter_setup_action} = Project.set_up_formatter_exs(project)

    try do
      case Project.mix_command(project, "format --check-formatted") do
        {_output, 0} ->
          {:ok, :clean}

        {_output, 1} ->
          with :ok <- format(project),
               :ok <- cleanup(project, mix_exs_action, formatter_setup_action),
               :ok <- commit_format_changes(project) do
            {:ok, :created_format_commit}
          end

        {output, exit_code} ->
          {:error, "mix format failed with exit code #{exit_code}: #{output}"}
      end
    after
      :ok = cleanup(project, mix_exs_action, formatter_setup_action)
    end
  end

  defp cleanup(project, mix_exs_action, formatter_setup_action) do
    :ok = MixExs.reset(project, mix_exs_action)
    :ok = FormatterExs.reset(project, formatter_setup_action)
  end

  @spec format(Project.t()) :: :ok | {:error, String.t()}
  defp format(%Project{} = project) do
    case Project.mix_command(project, "format") do
      {_output, 0} ->
        :ok

      {output, exit_code} ->
        {:error, "mix format failed with exit code #{exit_code}: #{output}"}
    end
  end

  @spec commit_format_changes(Project.t()) :: :ok
  defp commit_format_changes(%Project{} = project) do
    project_path = Project.path(project)

    System.cmd("git", ["add", "."], cd: project_path)

    System.cmd(
      "git",
      ["commit", "-m", "Baseline formatting commit for Green validation of #{project.name}"],
      cd: project_path,
      stderr_to_stdout: true
    )

    :ok
  end
end
