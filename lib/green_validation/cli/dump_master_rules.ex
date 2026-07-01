defmodule GreenValidation.CLI.DumpMasterRules do
  @moduledoc """
  CLI tool that writes the master rule list (`GreenValidation.StyleCatalog`) to a JSON
  file so it can be reviewed and diffed as it grows.
  """

  alias GreenValidation.StyleCatalog

  require Logger

  @program "mix green_validation.dump_master_rules"

  @commands [
    %{
      commands: [],
      description: "Write the master rule list to JSON",
      switches: [
        output_path: %{
          type: :string,
          description: "Output file path",
          default: "style_sources/master_rules.json"
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

    case write_json(output_path, StyleCatalog.all()) do
      :ok ->
        Logger.info("Wrote #{length(StyleCatalog.all())} master rules to #{output_path}")
        {:ok, output_path}

      {:error, reason} ->
        Logger.info("Error: #{reason}")
        System.halt(1)
    end
  end

  defp write_json(path, rules) do
    with :ok <- path |> Path.dirname() |> File.mkdir_p(),
         {:ok, iodata} <- Jason.encode_to_iodata(rules, pretty: true),
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
