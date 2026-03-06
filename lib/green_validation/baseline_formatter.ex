defmodule GreenValidation.BaselineFormatter do
  @moduledoc """
  Performs baseline formatting checks on projects without Green formatter.
  """

  alias GreenValidation.Project
  alias GreenValidation.Installer.MixExs

  @doc """
  Checks if a project is already formatted according to Elixir's standard formatter.

  If not, commits the necessary changes to create a baseline for Green formatter to compare against.
  """
  @spec ensure_clean(Project.t()) ::
          {:ok, :clean | :created_format_commit} | {:error, String.t()}
  def ensure_clean(%Project{} = project) do
    MixExs.ensure_mix_exs(project)
    project_path = Project.path(project)
    environment = Project.environment(project)

    try do
      case System.cmd("mix", ["format", "--check-formatted"],
             cd: project_path,
             env: environment,
             stderr_to_stdout: true
           ) do
        {_output, 0} ->
          {:ok, :clean}

        {_output, 1} ->
          with :ok <- format(project),
               :ok <- cleanup(project),
               :ok <- commit_format_changes(project) do
            {:ok, :created_format_commit}
          end

        {output, exit_code} ->
          {:error, "mix format failed with exit code #{exit_code}: #{output}"}
      end
    after
      :ok = cleanup(project)
    end
  end

  defp cleanup(project) do
    :ok = MixExs.reset_mix_exs(project)
  end

  @spec format(Project.t()) :: :ok | {:error, String.t()}
  defp format(%Project{} = project) do
    project_path = Project.path(project)
    environment = Project.environment(project)

    case System.cmd("mix", ["format"],
           cd: project_path,
           env: environment,
           stderr_to_stdout: true
         ) do
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
