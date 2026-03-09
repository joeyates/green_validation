defmodule GreenValidation.ClonedRepo do
  alias GreenValidation.Project

  @enforce_keys [:project, :commit_sha, :branch]
  defstruct [:project, :commit_sha, :branch]

  @type t :: %__MODULE__{
          project: Project.t(),
          commit_sha: String.t(),
          branch: String.t()
        }
end
