defmodule GreenValidation.GreenInstaller do
  @moduledoc """
  Handles temporary installation of Green formatter in projects for validation.
  """

  alias GreenValidation.{GreenDependency, Installer, Project}
  alias Installer.{MixExs, FormatterExs}

  @doc """
  Temporarily modifies project's mix.exs and .formatter.exs to use Green formatter.
  """

  @spec install_green(Project.t(), keyword()) :: :updated | :created | {:error, String.t()}
  def install_green(%Project{} = project, opts \\ []) do
    supplied_version = Keyword.get(opts, :green_version)

    green_version =
      cond do
        is_nil(supplied_version) -> get_latest_green_version()
        true -> supplied_version
      end

    with :ok <- reset_project(project) do
      MixExs.add_dependency(project, GreenDependency.to_dep(green_version))
    end
  end

  @spec prepare_formatter_exs(Project.t(), list() | :all | nil) ::
          {:ok, :none | :created | :updated}
  def prepare_formatter_exs(%Project{} = project, rules \\ nil) do
    {:ok, formatter_setup_action} = Project.set_up_formatter_exs(project)
    green_config = green_config_for_rules(rules)
    FormatterExs.update_project_formatter(project, green_config)
    combined_action = if formatter_setup_action == :created, do: :created, else: :updated

    {:ok, combined_action}
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

  @spec get_latest_green_version() :: GreenDependency.t()
  defp get_latest_green_version() do
    # For now, hardcode version - could query hex.pm API in the future
    %GreenDependency{version: "0.1.10"}
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
