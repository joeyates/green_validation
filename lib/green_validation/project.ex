defmodule GreenValidation.Project do
  @moduledoc """
  A struct representing a project in a repository.
  """

  alias GreenValidation.{Repo, Repos}

  @enforce_keys [:name, :repo_name]
  defstruct [:name, :repo_name, :environment, rule_config: [], has_formatter_exs: true, has_mix_exs: true]

  @type t :: %__MODULE__{
          name: String.t(),
          repo_name: String.t(),
          environment: {atom, atom} | nil,
          rule_config: list({atom, keyword()}),
          has_formatter_exs: boolean(),
          has_mix_exs: boolean()
        }

  @spec path(t()) :: String.t()
  def path(%__MODULE__{repo_name: repo_name}) do
    Path.join(Repo.base_dir(), repo_name)
  end

  @spec repo(t()) :: {:ok, Repo.t()} | {:error, String.t()}
  def repo(%__MODULE__{repo_name: repo_name}) do
    Repos.find_by_name(repo_name)
  end

  def environment(%__MODULE__{environment: {module, fun}} = project) do
    apply(module, fun, [project])
  end

  def environment(%__MODULE__{}), do: []

  def rule_config(%__MODULE__{rule_config: rule_config}, rule, config) do
    Keyword.put(config, rule, rule_config[rule])
  end

  @spec install_deps(t()) :: :ok | {:error, String.t()}
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

  @spec compile(t()) :: :ok | {:error, String.t()}
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
