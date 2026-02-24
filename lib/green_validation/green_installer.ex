defmodule GreenValidation.GreenInstaller do
  @moduledoc """
  Handles temporary installation of Green formatter in projects for validation.
  """

  alias GreenValidation.{Installer, Project}
  alias Installer.MixExs

  @doc """
  Temporarily modifies project's mix.exs and .formatter.exs to use Green formatter.
  """

  @spec install_green(Project.t(), keyword()) :: :ok | {:error, String.t()}
  def install_green(%Project{} = project, opts \\ []) do
    installation_type = Keyword.get(opts, :installation_type)
    supplied_version = Keyword.get(opts, :green_version)

    green_version =
      cond do
        !is_nil(supplied_version) -> supplied_version
        installation_type == :local -> local_green_dependency()
        true -> get_latest_green_version()
      end

    with :ok <- reset_project(project),
         :ok <- modify_mix_exs(project, green_version),
         :ok <- Project.install_deps(project),
         :ok <- Project.compile(project) do
      :ok
    end
  end

  def prepare_formatter_exs(%Project{} = project, rules \\ nil) do
    :ok = reset_formatter_exs(project)
    project_path = Project.path(project)
    formatter_path = Path.join(project_path, ".formatter.exs")

    parsed = parsed_formatter_config(project_path)
    modified = update_formatter_config(parsed, rules)
    File.write!(formatter_path, modified)

    :ok
  end

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

  defp reset_formatter_exs(%Project{has_formatter_exs: true} = project) do
    project_path = Project.path(project)

    case System.cmd("git", ["reset", ".formatter.exs"],
           cd: project_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to reset .formatter.exs: #{output}"}
    end
  end

  defp reset_formatter_exs(%Project{has_formatter_exs: false} = project) do
    project_path = Project.path(project)

    System.cmd("rm", [".formatter.exs"],
      cd: project_path,
      stderr_to_stdout: true
    )

    :ok
  end

  defp reset_mix_exs(%Project{} = project) do
    project_path = Project.path(project)

    case System.cmd("git", ["reset", "mix.exs"],
           cd: project_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to reset mix.exs: #{output}"}
    end
  end

  defp get_latest_green_version do
    # For now, hardcode version - could query hex.pm API in the future
    {:green, "0.1.10"}
  end

  def local_green_dependency do
    # From test/projects/validation/lib -> root of green project
    path = [__DIR__, "..", "..", "..", "..", ".."] |> Path.join() |> Path.expand()

    {:green, ">= 0.0.0", path: path}
  end

  defp modify_mix_exs(%Project{} = project, green_version) do
    :ok = reset_mix_exs(project)
    MixExs.add_dependency(project, green_version)

    :ok
  end

  defp parsed_formatter_config(project_path) do
    formatter_path = Path.join(project_path, ".formatter.exs")

    if File.exists?(formatter_path) do
      content = File.read!(formatter_path)
      {config, _} = Code.eval_string(content)
      config
    else
      []
    end
  end

  defp update_formatter_config(base_config, rules) do
    green_config =
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

    merged = Keyword.merge(base_config, green_config)

    merged =
      if merged[:inputs] do
        merged
      else
        Keyword.put(merged, :inputs, ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"])
      end

    """
    #{inspect(merged, pretty: true, width: 80, limit: :infinity)}
    """
  end
end
