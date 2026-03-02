defmodule GreenValidation.TestRun do
  @moduledoc """
  Represents a test run for a project, including metadata about the project and the environment in which the tests were run.
  """

  @enforce_keys [:project_name, :repository, :commit_sha, :branch, :green_version]
  defstruct [:project_name, :repository, :commit_sha, :branch, :green_version]

  @type t :: %__MODULE__{
          project_name: String.t(),
          repository: String.t(),
          commit_sha: String.t(),
          branch: String.t(),
          green_version: String.t()
        }
end
