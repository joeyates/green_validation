defmodule GreenValidation.Repos do
  @moduledoc """
  The list of repositories handled by the validation suite. This module defines the list of repositories to validate and provides helper functions to access their paths and metadata.
  """

  alias GreenValidation.Repo

  @repos [
    %Repo{
      name: "elixir",
      post_checkout: {__MODULE__, :post_checkout_elixir},
      repo: "https://github.com/elixir-lang/elixir.git"
    },
    %Repo{
      name: "phoenix",
      repo: "https://github.com/phoenixframework/phoenix.git"
    },
    %Repo{
      name: "phoenix_live_view",
      repo: "https://github.com/phoenixframework/phoenix_live_view.git"
    },
    %Repo{
      name: "hexpm",
      repo: "https://github.com/hexpm/hexpm.git"
    },
    %Repo{
      name: "nerves",
      repo: "https://github.com/nerves-project/nerves.git"
    },
    %Repo{
      name: "absinthe",
      repo: "https://github.com/absinthe-graphql/absinthe.git"
    },
    %Repo{
      name: "broadway",
      repo: "https://github.com/dashbitco/broadway.git"
    },
    %Repo{
      name: "credo",
      repo: "https://github.com/rrrene/credo.git",
      default_branch: "master"
    }
  ]

  @doc """
  Returns the list of repositories to validate.
  """
  @spec all() :: list(Repo.t())
  def all(), do: @repos

  @spec find_by_name(String.t()) :: {:ok, Repo.t()} | {:error, String.t()}
  def find_by_name(name) do
    case Enum.find(all(), &(&1.name == name)) do
      nil -> {:error, "Repository not found: #{name}"}
      repo -> {:ok, repo}
    end
  end

  def post_checkout_elixir(%Repo{} = repo) do
    IO.puts("Running post-checkout step, 'make', for Elixir repository...")
    path = Repo.path(repo)

    case System.cmd("make", [], cd: path, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok
      {output, _} ->
        {:error, "Failed to run post-checkout step for Elixir: #{output}"}
    end
  end
end
