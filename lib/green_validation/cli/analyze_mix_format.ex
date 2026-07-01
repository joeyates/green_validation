defmodule GreenValidation.CLI.AnalyzeMixFormat do
  @moduledoc """
  CLI tool that runs the `mix format` analysis and writes the per-source artifact to
  `style_sources/sources/mix_format.json`.
  """

  alias GreenValidation.Sources.MixFormat
  alias GreenValidation.SourceArtifact

  require Logger

  @program "mix green_validation.analyze_mix_format"

  @commands [
    %{
      commands: [],
      description: "Analyse which master rules mix format enforces",
      switches: [
        output_path: %{
          type: :string,
          description: "Output file path",
          default: "style_sources/sources/mix_format.json"
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
    output_path = Map.get(switches, :output_path)
    %{rules: rules, unmapped: unmapped} = MixFormat.analyze()

    case SourceArtifact.write(output_path, :mix_format, rules, unmapped) do
      {:ok, path} ->
        Logger.info("Wrote #{length(rules)} mix format rules to #{path}")
        {:ok, path}

      {:error, reason} ->
        Logger.info("Error: #{reason}")
        System.halt(1)
    end
  end

  defp usage() do
    IO.puts("""
    Usage:
      #{HelpfulOptions.help_commands!(@program, @commands)}
    """)
  end
end
