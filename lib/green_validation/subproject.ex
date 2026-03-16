defmodule GreenValidation.Subproject do
  @moduledoc """
  A struct representing a subproject in a repository.

  Subprojects are needed when a repository is a monorepo containing multiple projects,
  not all of which are in Elixir.
  """

  @enforce_keys [:path]
  defstruct [:mix_exs_add_dependency, :path, has_mix_exs: true]
end
