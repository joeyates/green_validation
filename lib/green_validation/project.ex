defmodule GreenValidation.Project do
  @moduledoc """
  A struct representing a project in a repository.
  """

  alias GreenValidation.{ClonedRepo, Subproject}
  alias GreenValidation.Installer.{FormatterExs, MixExs}

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

  def tool_versions_path(%__MODULE__{} = project) do
    project |> path() |> Path.join(".tool-versions")
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

    streamer =
      CollectableStreamer.new(fn line -> Logger.debug("=> #{String.trim_trailing(line)}") end,
        collect: true
      )

    case System.cmd("git", ["clone", "--depth", "1", project.url, path],
           stderr_to_stdout: true,
           into: streamer
         ) do
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

  defp post_checkout(%__MODULE__{} = project) do
    if uses_asdf?(project) do
      run_asdf_install(project)
    end

    :ok
  end

  def uses_asdf?(%__MODULE__{} = project) do
    project |> tool_versions_path() |> File.exists?()
  end

  @spec install_deps(t()) :: :ok | {:error, String.t()}
  def install_deps(%__MODULE__{} = project) do
    Logger.info("  Installing dependencies")
    mix_exs_action = MixExs.ensure_mix_exs(project)
    project_path = path(project)
    environment = command_env(project)

    streamer =
      CollectableStreamer.new(fn line -> Logger.debug("=> #{String.trim_trailing(line)}") end,
        collect: true
      )

    result =
      case System.shell("mix deps.get",
             cd: project_path,
             env: environment,
             stderr_to_stdout: true,
             into: streamer
           ) do
        {_output, 0} ->
          :ok

        {output, _} ->
          Logger.error("Failed to install dependencies for #{project.name}: #{output}")
          {:error, "Failed to install deps: #{output}"}
      end

    :ok = MixExs.reset(project, mix_exs_action)

    result
  end

  def compile(%__MODULE__{} = project) do
    Logger.info("  Compiling project")
    mix_exs_action = MixExs.ensure_mix_exs(project)

    result =
      case mix_command(project, "compile") do
        {_output, 0} ->
          :ok

        {output, _error_code} ->
          message = "Failed to compile #{project.name}:\n#{output}"
          Logger.error(message)
          {:error, message}
      end

    :ok = MixExs.reset(project, mix_exs_action)
    result
  end

  def mix_command(%__MODULE__{} = project, command) do
    project_path = path(project)
    environment = command_env(project)

    prefix =
      if uses_asdf?(project) do
        "asdf exec "
      else
        ""
      end

    full_command = "#{prefix}mix #{command}"
    Logger.debug("Running command: #{full_command} for #{project.name} in #{project_path}")

    streamer =
      CollectableStreamer.new(fn line -> Logger.debug("=> #{String.trim_trailing(line)}") end,
        collect: true
      )

    {updated, exit_code} =
      System.shell(
        full_command,
        cd: project_path,
        env: environment,
        stderr_to_stdout: true,
        into: streamer
      )

    {to_string(updated), exit_code}
  end

  def run_asdf_install(%__MODULE__{} = project) do
    run_command(project, "asdf install")
  end

  def run_command(%__MODULE__{} = project, command) do
    path = path(project)

    streamer =
      CollectableStreamer.new(fn line -> Logger.debug("=> #{String.trim_trailing(line)}") end,
        collect: true
      )

    Logger.debug("Running command: #{inspect(command)} for #{project.name} in #{inspect(path)}")

    case System.shell(command, cd: path, stderr_to_stdout: true, into: streamer) do
      {_output1, 0} ->
        :ok

      {output, _} ->
        {:error, "Failed to run 'asdf install' for #{project.name}: #{output}"}
    end
  end

  @leaked_runtime_vars ~w(
    ROOTDIR BINDIR EMU PROGNAME
    ASDF_INSTALL_VERSION ASDF_INSTALL_TYPE ASDF_INSTALL_PATH
    MIX_HOME MIX_ARCHIVES
  )

  defp sanitize_asdf_env(env) do
    path = env_value(env, "PATH") || System.get_env("PATH") || ""

    env
    |> List.keystore("PATH", 0, {"PATH", clean_asdf_path(path)})
    |> unset_leaked_vars()
  end

  defp clean_asdf_path(path) do
    path
    |> String.split(":")
    |> Enum.reject(&String.contains?(&1, ["/.asdf/installs/", "/.asdf/plugins/"]))
    |> Enum.join(":")
  end

  defp unset_leaked_vars(env) do
    Enum.reduce(@leaked_runtime_vars, env, fn var, acc ->
      List.keystore(acc, var, 0, {var, nil})
    end)
  end

  defp env_value(env, key) do
    case List.keyfind(env, key, 0) do
      {^key, value} -> value
      nil -> nil
    end
  end

  defp command_env(%__MODULE__{} = project) do
    environment = environment(project)

    if uses_asdf?(project) do
      sanitize_asdf_env(environment)
    else
      environment
    end
  end
end
