defmodule GreenValidation.CLI.AnalyzeGuide do
  @moduledoc """
  Parameterised CLI shared by every prose-guide analysis command.

  Reads the vendored guide markdown from `<guides-path>/<id>.md`, runs
  `GreenValidation.GuideAnalyzer` against the source's curated mapping, writes the
  per-source artifact to `<output-path>`, and logs any anchor drift.
  """

  alias GreenValidation.GuideAnalyzer
  alias GreenValidation.SourceArtifact
  alias GreenValidation.StyleSource

  require Logger

  @program "mix green_validation.analyze_<guide>"

  @switches [
    guides_path: %{
      type: :string,
      description: "Directory holding the vendored guide markdown",
      default: "style_sources/guides"
    },
    output_path: %{
      type: :string,
      description: "Output file path (defaults to style_sources/sources/<id>.json)"
    }
  ]

  @spec main([String.t()], StyleSource.id(), [{atom(), String.t()}]) ::
          {:ok, String.t()} | no_return()
  def main(args, source_id, mapping) do
    commands = [%{commands: [], description: "Analyse a prose style guide", switches: @switches}]

    case HelpfulOptions.parse_commands(args, commands) do
      {:ok, parsed} ->
        run(parsed, source_id, mapping)

      {:error, reason} ->
        Logger.info("Invalid parameters: #{inspect(reason)}")
        usage(commands)
        System.halt(1)
    end
  end

  defp run(%{switches: switches}, source_id, mapping) do
    source = Enum.find(StyleSource.all(), &(&1.id == source_id))
    guides_path = Map.get(switches, :guides_path)
    output_path = Map.get(switches, :output_path) || default_output(source_id)
    guide_path = Path.join(guides_path, "#{source_id}.md")

    with {:ok, markdown} <- File.read(guide_path),
         %{rules: rules, unmapped: unmapped, drift: drift} <-
           GuideAnalyzer.analyze(source, markdown, mapping),
         :ok <- log_drift(source_id, drift),
         {:ok, path} <- SourceArtifact.write(output_path, source_id, rules, unmapped) do
      Logger.info("Wrote #{length(rules)} #{source_id} rules to #{path}")
      {:ok, path}
    else
      {:error, reason} ->
        Logger.info("Error analysing #{source_id}: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp default_output(source_id), do: "style_sources/sources/#{source_id}.json"

  defp log_drift(_source_id, []), do: :ok

  defp log_drift(source_id, drift) do
    anchors = Enum.map_join(drift, ", ", & &1.anchor)

    Logger.warning(
      "#{source_id}: #{length(drift)} mapping anchor(s) no longer resolve: #{anchors}"
    )

    :ok
  end

  defp usage(commands) do
    IO.puts("""
    Usage:
      #{HelpfulOptions.help_commands!(@program, commands)}
    """)
  end
end
