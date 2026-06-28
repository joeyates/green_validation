defmodule GreenValidation.CLI.CompareStyles do
  @moduledoc """
  CLI tool that reads the per-source artifacts under `style_sources/sources/` and joins
  them into `style_sources/comparison.json`. A source whose artifact is missing is
  treated as absent, so the command produces useful partial output before every analyzer
  has run.
  """

  alias GreenValidation.StyleComparison
  alias GreenValidation.StyleSource

  require Logger

  @program "mix green_validation.compare_styles"

  @commands [
    %{
      commands: [],
      description: "Join the per-source artifacts into a comparison",
      switches: [
        sources_path: %{
          type: :string,
          description: "Directory holding the per-source artifacts",
          default: "style_sources/sources"
        },
        output_path: %{
          type: :string,
          description: "Output file path",
          default: "style_sources/comparison.json"
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
    sources_path = Map.get(switches, :sources_path)
    output_path = Map.get(switches, :output_path)

    comparison =
      sources_path
      |> read_sources()
      |> StyleComparison.build()

    log_no_source(comparison.rules_with_no_source)

    case write_json(output_path, comparison) do
      :ok ->
        Logger.info("Wrote comparison of #{length(comparison.rules)} rules to #{output_path}")
        {:ok, output_path}

      {:error, reason} ->
        Logger.info("Error: #{reason}")
        System.halt(1)
    end
  end

  defp read_sources(sources_path) do
    Enum.reduce(StyleSource.all(), %{}, fn source, acc ->
      path = Path.join(sources_path, "#{source.id}.json")

      case File.read(path) do
        {:ok, content} ->
          %{rules: rules} = Jason.decode!(content, keys: :atoms)
          Map.put(acc, source.id, Enum.map(rules, &normalize_rule/1))

        {:error, _reason} ->
          Logger.info("No artifact for #{source.id} at #{path}; treating as absent")
          acc
      end
    end)
  end

  defp normalize_rule(rule) do
    %{id: String.to_existing_atom(rule.id), proposed: rule.proposed, reference: rule[:reference]}
  end

  defp log_no_source([]), do: :ok

  defp log_no_source(ids) do
    Logger.warning("#{length(ids)} master rule(s) proposed by no source: #{inspect(ids)}")
    :ok
  end

  defp write_json(path, comparison) do
    with :ok <- path |> Path.dirname() |> File.mkdir_p(),
         {:ok, iodata} <- Jason.encode_to_iodata(comparison, pretty: true),
         :ok <- File.write(path, iodata) do
      :ok
    else
      {:error, reason} -> {:error, "Failed to write file #{path}: #{inspect(reason)}"}
    end
  end

  defp usage() do
    IO.puts("""
    Usage:
      #{HelpfulOptions.help_commands!(@program, @commands)}
    """)
  end
end
