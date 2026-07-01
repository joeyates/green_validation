defmodule GreenValidation.SourceArtifact do
  @moduledoc """
  Builds and writes a per-source rule artifact as pretty JSON. Shared by every source
  analysis command.

  The artifact shape is:

      %{
        "source" => %{"id" => ..., "name" => ..., "repo_url" => ...},
        "rules" => [%{"id" => ..., "proposed" => ..., "reference" => ...}, ...],
        "unmapped" => [...]
      }
  """

  alias GreenValidation.StyleSource

  @spec to_map(StyleSource.id(), [map()], [map()]) :: map()
  def to_map(source_id, rules, unmapped) do
    source = Enum.find(StyleSource.all(), &(&1.id == source_id))

    %{
      source: %{id: source.id, name: source.name, repo_url: source.repo_url},
      rules: rules,
      unmapped: unmapped
    }
  end

  @spec write(String.t(), StyleSource.id(), [map()], [map()]) ::
          {:ok, String.t()} | {:error, String.t()}
  def write(path, source_id, rules, unmapped \\ []) do
    map = to_map(source_id, rules, unmapped)

    with :ok <- path |> Path.dirname() |> File.mkdir_p(),
         {:ok, iodata} <- Jason.encode_to_iodata(map, pretty: true),
         :ok <- File.write(path, iodata) do
      {:ok, path}
    else
      {:error, reason} -> {:error, "Failed to write file #{path}: #{inspect(reason)}"}
    end
  end
end
