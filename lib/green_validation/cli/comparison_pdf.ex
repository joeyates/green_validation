defmodule GreenValidation.CLI.ComparisonPdf do
  @moduledoc """
  CLI tool that renders the style comparison (`style_sources/comparison.json`, produced
  by `mix green_validation.compare_styles`) to a PDF using `GreenValidation.ComparisonPdf`.
  """

  alias GreenValidation.ComparisonPdf

  require Logger

  @program "mix green_validation.comparison_pdf"

  @commands [
    %{
      commands: [],
      description: "Render the style comparison as a PDF",
      switches: [
        input_path: %{
          type: :string,
          description: "Path to the comparison JSON",
          default: "style_sources/comparison.json"
        },
        output_path: %{
          type: :string,
          description: "Output PDF path",
          default: "style_sources/comparison.pdf"
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
    input_path = Map.get(switches, :input_path)
    output_path = Map.get(switches, :output_path)

    with {:ok, content} <- File.read(input_path),
         {:ok, comparison} <- Jason.decode(content),
         pdf <- ComparisonPdf.render(comparison),
         :ok <- output_path |> Path.dirname() |> File.mkdir_p(),
         :ok <- File.write(output_path, pdf) do
      Logger.info("Wrote comparison PDF to #{output_path}")
      {:ok, output_path}
    else
      {:error, reason} ->
        Logger.info("Error: #{inspect(reason)}")
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
