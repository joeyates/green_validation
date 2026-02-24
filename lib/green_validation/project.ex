defmodule GreenValidation.Project do
  @moduledoc """
  A struct representing a project in a repository.
  """

  alias GreenValidation.{Repo, Repos}

  @enforce_keys [:name, :repo_name]
  defstruct [:name, :repo_name, :path, has_formatter_exs: true]

  @type t :: %__MODULE__{
          name: String.t(),
          repo_name: String.t(),
          path: String.t() | nil,
          has_formatter_exs: boolean()
        }

  def path(%__MODULE__{repo_name: repo_name, path: path}) when is_binary(path) do
    Path.join([Repo.base_dir(), repo_name, path])
  end

  def path(%__MODULE__{repo_name: repo_name}) do
    Path.join(Repo.base_dir(), repo_name)
  end

  def repo(%__MODULE__{repo_name: repo_name}) do
    Repos.find_by_name(repo_name)
  end

  def has_mix_exs?(%__MODULE__{} = project) do
    project_path = path(project)

    if File.exists?(Path.join(project_path, "mix.exs")) do
      :ok
    else
      {:error, "No mix.exs found in #{project_path}"}
    end
  end

  def install_deps(%__MODULE__{} = project) do
    project_path = path(project)

    case System.cmd("mix", ["deps.get"],
           cd: project_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to install deps: #{output}"}
    end
  end

  def compile(%__MODULE__{} = project) do
    project_path = path(project)

    case System.cmd("mix", ["compile"],
           cd: project_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to compile project: #{output}"}
    end
  end
end
