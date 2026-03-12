defmodule GreenValidation.GreenDependency do
  @moduledoc """
  A struct representing the Green dependency added to projects for validation purposes.
  """

  defstruct [:version, :path]

  @type t :: %__MODULE__{
          version: String.t() | nil,
          path: String.t() | nil
        }

  def new(version_or_path) do
    cond do
      File.dir?(version_or_path) ->
        green_path = Path.expand(version_or_path)
        {:ok, %__MODULE__{path: green_path}}

      Regex.match?(~r"\d+\.\d+\.\d+$", version_or_path) ->
        {:ok, %__MODULE__{version: version_or_path}}

      true ->
        {:error,
         "Invalid --green argument. Must be a version tag (e.g. '0.1.0') or a path to a local checkout of the Green repository."}
    end
  end

  def to_dep(%__MODULE__{version: version}) when is_binary(version) do
    {:green, version}
  end

  def to_dep(%__MODULE__{path: local_path}) when is_binary(local_path) do
    {:green, path: local_path}
  end

  def get_version(%__MODULE__{version: version}) when is_binary(version), do: {:ok, version}

  def get_version(%__MODULE__{path: local_path}) when is_binary(local_path) do
    case System.cmd("git", ["rev-parse", "HEAD"],
           cd: local_path,
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, String.trim(output)}
      {output, _} -> {:error, "Failed to get green SHA: #{output}"}
    end
  end
end
