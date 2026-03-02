defmodule GreenValidation.Projects do
  @moduledoc """
  The projects handled by the validation suite. This module defines the list of projects to validate and provides helper functions to access their paths and metadata.
  """

  alias GreenValidation.Project

  @projects [
    %Project{
      name: "eex",
      repo_name: "elixir",
      path: "lib/eex",
      has_formatter_exs: false
    },
    # Commenting out Elixir for now as it needs extra work to compile and format
    # %Project{name: "elixir", repo_name: "elixir", path: "lib/elixir", has_formatter_exs: false},
    %Project{
      name: "ex_unit",
      repo_name: "elixir",
      path: "lib/ex_unit",
      has_formatter_exs: false
    },
    %Project{
      name: "iex",
      repo_name: "elixir",
      path: "lib/iex",
      has_formatter_exs: false
    },
    %Project{
      name: "logger",
      repo_name: "elixir",
      path: "lib/logger",
      has_formatter_exs: false
    },
    %Project{
      name: "mix",
      repo_name: "elixir",
      path: "lib/mix",
      has_formatter_exs: false
    },
    %Project{
      name: "phoenix",
      repo_name: "phoenix"
    },
    %Project{
      name: "phoenix_live_view",
      repo_name: "phoenix_live_view"
    },
    %Project{
      name: "hexpm",
      repo_name: "hexpm"
    },
    %Project{
      name: "nerves",
      repo_name: "nerves"
    },
    %Project{
      name: "absinthe",
      repo_name: "absinthe"
    },
    %Project{
      name: "broadway",
      repo_name: "broadway"
    },
    %Project{
      name: "credo",
      repo_name: "credo"
    }
  ]

  @spec all() :: list(Project.t())
  def all(), do: @projects

  @spec find_by_name(String.t()) :: {:ok, Project.t()} | {:error, String.t()}
  def find_by_name(project_name) do
    case Enum.find(all(), &(&1.name == project_name)) do
      nil -> {:error, "Project not found: #{project_name}"}
      project -> {:ok, project}
    end
  end
end
