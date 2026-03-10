defmodule GreenValidation.GreenInstaller do
  @moduledoc """
  Handles temporary installation of Green formatter in projects for validation.
  """

  alias GreenValidation.{Installer, Project}
  alias Installer.{MixExs, FormatterExs}

  @doc """
  Temporarily modifies project's mix.exs and .formatter.exs to use Green formatter.
  """

  @spec install_green(Project.t(), keyword()) :: :ok | {:error, String.t()}
  def install_green(%Project{} = project, opts \\ []) do
    supplied_version = Keyword.get(opts, :green_version)

    green_version =
      cond do
        !is_nil(supplied_version) -> supplied_version
        true -> get_latest_green_version()
      end

    with :ok <- reset_project(project),
         :ok <- modify_mix_exs(project, green_version),
         :ok <- Project.install_deps(project) do
      :ok
    end
  end

  @spec prepare_formatter_exs(Project.t(), list() | :all | nil) :: :ok
  def prepare_formatter_exs(%Project{} = project, rules \\ nil) do
    :ok = FormatterExs.reset(project)

    if project.formatter_exs_setup do
      {mod, fun} = project.formatter_exs_setup
      apply(mod, fun, [project])
    end

    green_config = green_config_for_rules(rules)
    FormatterExs.update_project_formatter(project, green_config)
  end

  @spec reset_project(Project.t()) :: :ok | {:error, String.t()}
  def reset_project(%Project{} = project) do
    project_path = Project.path(project)

    case System.cmd("git", ["reset", "--hard"],
           cd: project_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to reset project: #{output}"}
    end
  end

  @spec get_latest_green_version() :: {:green, String.t()}
  defp get_latest_green_version do
    # For now, hardcode version - could query hex.pm API in the future
    {:green, "0.1.10"}
  end

  @spec modify_mix_exs(Project.t(), tuple()) :: :ok
  defp modify_mix_exs(%Project{} = project, green_version) do
    :ok = MixExs.reset(project)
    MixExs.add_dependency(project, green_version)

    :ok
  end

  defp green_config_for_rules(rules) do
    case rules do
      nil ->
        []

      :all ->
        [plugins: [Green.Lexmag.ElixirStyleGuideFormatter]]

      individual_rules when is_list(individual_rules) ->
        [
          plugins: [Green.Lexmag.ElixirStyleGuideFormatter],
          green: individual_rules
        ]
    end
  end
end
