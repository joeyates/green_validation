defmodule GreenValidation.Project do
  @moduledoc """
  A struct representing a project in a repository.
  """

  alias GreenValidation.{ClonedRepo, Subproject}
  alias GreenValidation.Installer.FormatterExs

  require Logger

  @default_branch "main"

  @derive {Jason.Encoder, only: [:name, :url, :default_branch]}
  @enforce_keys [:name, :url]
  defstruct [
    :environment,
    :name,
    :path,
    :post_checkout,
    :mix_exs_add_dependency,
    :formatter_exs_setup,
    :url,
    default_branch: @default_branch,
    rule_config: [],
    has_mix_exs: true,
    subprojects: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t(),
          default_branch: String.t(),
          environment: {atom, atom} | nil,
          post_checkout: {atom, atom} | nil,
          mix_exs_add_dependency: {atom, atom} | nil,
          formatter_exs_setup: {atom, atom} | nil,
          rule_config: list({atom, keyword()}),
          has_mix_exs: boolean(),
          subprojects: list(Subproject.t())
        }

  @spec repos_dir() :: String.t()
  def repos_dir(), do: [__DIR__, "..", "..", "repos"] |> Path.join() |> Path.expand()

  @spec path(t()) :: String.t()
  def path(%__MODULE__{name: name, path: nil}) do
    Path.join(repos_dir(), name)
  end

  def path(%__MODULE__{name: name, path: path}) do
    Path.join([repos_dir(), name, path])
  end

  def formatter_exs_path(%__MODULE__{} = project) do
    project |> path() |> Path.join(".formatter.exs")
  end

  def mix_exs_path(%__MODULE__{} = project) do
    project |> path() |> Path.join("mix.exs")
  end

  def environment(%__MODULE__{environment: {module, fun}} = project) do
    apply(module, fun, [project])
  end

  def environment(%__MODULE__{}), do: []

  def module_name(%__MODULE__{name: name}) do
    name
    |> String.replace(~r/[^a-zA-Z0-9_\.]/, "_")
    |> String.replace(~r/^([0-9])/, "X\\1")
    |> Macro.camelize()
  end

  @spec set_up_formatter_exs(t()) :: {:ok, :none | :created | :updated}
  def set_up_formatter_exs(%__MODULE__{formatter_exs_setup: {mod, fun}} = project) do
    apply(mod, fun, [project])
  end

  def set_up_formatter_exs(%__MODULE__{} = project) do
    path = formatter_exs_path(project)

    if File.exists?(path) do
      {:ok, :none}
    else
      inputs = [
        inputs: ["{.formatter,mix}.exs", "**/*.{ex,exs}"]
      ]

      FormatterExs.create_project_formatter(project, inputs)
    end
  end

  def rule_config(%__MODULE__{rule_config: rule_config}, rule, config) do
    Keyword.put(config, rule, rule_config[rule])
  end

  @spec cloned?(t()) :: boolean()
  def cloned?(%__MODULE__{} = project) do
    project |> path() |> File.dir?()
  end

  @doc """
  Clones or updates a repository.
  """
  @spec clone(t()) :: {:ok, ClonedRepo.t()} | {:error, String.t()}
  def clone(%__MODULE__{} = project) do
    with :ok <- ensure_repo(project),
         {:ok, commit_sha} <- get_commit_sha(project),
         :ok <- post_checkout(project) do
      cloned_repo = %ClonedRepo{
        project: project,
        commit_sha: commit_sha,
        branch: project.default_branch
      }

      {:ok, cloned_repo}
    end
  end

  @spec ensure_repo(t()) :: :ok | {:error, String.t()}
  defp ensure_repo(%__MODULE__{} = project) do
    if cloned?(project) do
      prepare_cloned(project)
    else
      clone_repo(project)
    end
  end

  defp prepare_cloned(%__MODULE__{} = project) do
    Logger.info("Updating existing repository: #{project.name}")

    with :ok <- clean_repo(project),
         :ok <- update_repo(project) do
      :ok
    end
  end

  @spec clone_repo(t()) :: :ok | {:error, String.t()}
  defp clone_repo(%__MODULE__{} = project) do
    Logger.info("Cloning repository: #{project.name}")

    with :ok <- do_clone(project) do
      :ok
    end
  end

  @spec do_clone(t()) :: :ok | {:error, String.t()}
  defp do_clone(%__MODULE__{} = project) do
    path = path(project)

    case System.cmd("git", ["clone", project.url, path], stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to clone: #{output}"}
    end
  end

  @spec clean_repo(t()) :: :ok | {:error, String.t()}
  defp clean_repo(%__MODULE__{} = project) do
    path = path(project)
    origin = "origin/#{project.default_branch}"

    with {_output, 0} <- System.cmd("git", ["clean", "-ffdx"], cd: path, stderr_to_stdout: true),
         {_output, 0} <-
           System.cmd("git", ["reset", "--hard", origin], cd: path, stderr_to_stdout: true) do
      :ok
    else
      {output, _status} -> {:error, "Failed to clean existing repo: #{output}"}
    end
  end

  @spec update_repo(t()) :: :ok | {:error, String.t()}
  defp update_repo(%__MODULE__{} = project) do
    path = path(project)

    case System.cmd("git", ["fetch", "--all", "--prune"],
           cd: path,
           stderr_to_stdout: true
         ) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to fetch: #{output}"}
    end
  end

  @spec get_commit_sha(t()) :: {:ok, String.t()} | {:error, String.t()}
  defp get_commit_sha(%__MODULE__{} = project) do
    path = path(project)

    case System.cmd("git", ["rev-parse", "HEAD"],
           cd: path,
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, String.trim(output)}
      {output, _} -> {:error, "Failed to get commit SHA: #{output}"}
    end
  end

  @spec mix_exs_add_dependency(t()) :: :ok | {:error, String.t()}
  def mix_exs_add_dependency(%__MODULE__{mix_exs_add_dependency: {mod, fun}} = project) do
    apply(mod, fun, [project])
  end

  def mix_exs_add_dependency(_), do: :ok

  @spec post_checkout(t()) :: :ok | {:error, String.t()}
  defp post_checkout(%__MODULE__{post_checkout: {mod, fun}} = project) do
    apply(mod, fun, [project])
  end

  defp post_checkout(_), do: :ok

  @spec install_deps(t()) :: :ok | {:error, String.t()}
  def install_deps(%__MODULE__{has_mix_exs: false}), do: :ok

  def install_deps(%__MODULE__{} = project) do
    Logger.info("  Installing dependencies")
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
    Logger.info("  Compiling project")
    project_path = path(project)

    case System.cmd("mix", ["compile"],
           cd: project_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to compile: #{output}"}
    end
  end
end
