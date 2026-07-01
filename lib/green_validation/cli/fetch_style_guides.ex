defmodule GreenValidation.CLI.FetchStyleGuides do
  @moduledoc """
  Downloads the prose style guides' markdown and vendors them under
  `style_sources/guides/`, recording their source URLs in a `manifest.json` for
  provenance. Network-only; the analysis commands read the vendored copies.
  """

  alias GreenValidation.StyleSource

  require Logger

  @program "mix green_validation.fetch_style_guides"

  @commands [
    %{
      commands: [],
      description: "Download and vendor the prose style guides",
      switches: [
        guides_path: %{
          type: :string,
          description: "Directory to vendor the guides into",
          default: "style_sources/guides"
        }
      ]
    }
  ]

  @spec main([String.t()]) :: {:ok, String.t()} | no_return()
  def main(args) do
    case HelpfulOptions.parse_commands(args, @commands) do
      {:ok, parsed} ->
        run(parsed)

      {:error, reason} ->
        Logger.info("Invalid parameters: #{inspect(reason)}")
        usage()
        System.halt(1)
    end
  end

  defp run(%{switches: switches}) do
    guides_path = Map.get(switches, :guides_path)
    File.mkdir_p!(guides_path)

    manifest =
      Enum.map(StyleSource.prose(), fn source ->
        {:ok, body} = fetch(source.raw_url)
        guides_path |> Path.join("#{source.id}.md") |> File.write!(body)
        Logger.info("Vendored #{source.id} from #{source.raw_url}")
        %{id: source.id, raw_url: source.raw_url, branch: source.branch}
      end)

    manifest_json = Jason.encode_to_iodata!(manifest, pretty: true)
    guides_path |> Path.join("manifest.json") |> File.write!(manifest_json)

    {:ok, guides_path}
  end

  defp fetch(url) do
    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, to_string(body)}
      {:ok, %Req.Response{status: status}} -> raise "Failed to fetch #{url}: HTTP #{status}"
      {:error, reason} -> raise "Failed to fetch #{url}: #{inspect(reason)}"
    end
  end

  defp usage() do
    IO.puts("""
    Usage:
      #{HelpfulOptions.help_commands!(@program, @commands)}
    """)
  end
end
