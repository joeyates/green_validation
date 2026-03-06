defmodule GreenValidation.ClonedRepo do
  @enforce_keys [:name, :repo, :commit_sha, :branch]
  defstruct [:name, :repo, :commit_sha, :branch]

  @type t :: %__MODULE__{
          name: String.t(),
          repo: String.t(),
          commit_sha: String.t(),
          branch: String.t()
        }
  
end