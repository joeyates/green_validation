defmodule GreenValidation.Repo do
  @moduledoc """
  Handles cloning and preparing Elixir project repositories for validation.
  """

  @default_branch "main"

  @enforce_keys [:name, :repo]
  defstruct [:name, :repo, :commit_sha, default_branch: @default_branch]

  @type t :: %__MODULE__{
          name: String.t(),
          repo: String.t(),
          commit_sha: String.t() | nil,
          default_branch: String.t()
        }

  @spec base_dir() :: String.t()
  def base_dir(), do: [__DIR__, "..", "..", "repos"] |> Path.join() |> Path.expand()

  @spec path(t()) :: String.t()
  def path(%__MODULE__{name: name}) do
    Path.join(base_dir(), name)
  end

  @spec cloned?(t()) :: boolean()
  def cloned?(%__MODULE__{} = repo) do
    File.dir?(path(repo))
  end

  @doc """
  Clones or updates a repository and checks out the default branch.

  Returns `{:ok, metadata}` or `{:error, reason}`.
  """
  @spec clone(t()) :: {:ok, t()} | {:error, String.t()}
  def clone(%__MODULE__{} = repo) do
    with :ok <- ensure_repo(repo),
         {:ok, commit_sha} <- get_commit_sha(repo) do
      repo = %{repo | commit_sha: commit_sha}

      {:ok, repo}
    end
  end

  @spec ensure_repo(t()) :: :ok | {:error, String.t()}
  defp ensure_repo(%__MODULE__{} = repo) do
    if cloned?(repo) do
      prepare_cloned(repo)
    else
      clone_repo(repo)
    end
  end

  defp prepare_cloned(%__MODULE__{} = repo) do
    IO.puts("Updating existing repository: #{repo.name}")
    with :ok <- clean_repo(repo),
         :ok <- update_repo(repo) do
      :ok
    end
  end

  @spec clone_repo(t()) :: :ok | {:error, String.t()}
  defp clone_repo(%__MODULE__{} = repo) do
    IO.puts("Cloning repository: #{repo.name}")
    with :ok <- do_clone(repo) do
      :ok
    end
  end

  @spec do_clone(t()) :: :ok | {:error, String.t()}
  defp do_clone(%__MODULE__{} = repo) do
    path = path(repo)

    case System.cmd("git", ["clone", repo.repo, path], stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to clone: #{output}"}
    end
  end

  @spec clean_repo(t()) :: :ok | {:error, String.t()}
  defp clean_repo(%__MODULE__{} = repo) do
    path = path(repo)
    origin = "origin/#{repo.default_branch}"

    with {_output, 0} <- System.cmd("git", ["clean", "-ffdx"], cd: path, stderr_to_stdout: true),
         {_output, 0} <-
           System.cmd("git", ["reset", "--hard", origin], cd: path, stderr_to_stdout: true) do
      :ok
    else
      {output, _status} -> {:error, "Failed to clean existing repo: #{output}"}
    end
  end

  @spec update_repo(t()) :: :ok | {:error, String.t()}
  defp update_repo(%__MODULE__{} = repo) do
    path = path(repo)

    case System.cmd("git", ["fetch", "--all", "--prune"],
           cd: path,
           stderr_to_stdout: true
         ) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Failed to fetch: #{output}"}
    end
  end

  @spec get_commit_sha(t()) :: {:ok, String.t()} | {:error, String.t()}
  defp get_commit_sha(%__MODULE__{} = repo) do
    path = path(repo)

    case System.cmd("git", ["rev-parse", "HEAD"],
           cd: path,
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, String.trim(output)}
      {output, _} -> {:error, "Failed to get commit SHA: #{output}"}
    end
  end
end
