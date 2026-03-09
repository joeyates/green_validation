#!/usr/bin/env elixir

Mix.install([
  {:helpful_options, "~> 0.4.4"},
  {:jason, "~> 1.4"}
])

defmodule GreenValidation.MergeSources do
  @moduledoc """
  CLI tool to merge and sort JSON files representing:
  1. the most starred Elixir repos on GitHub
  2. the most downloaded Projects on hex.pm
  """

  @switches [
    github_path: %{
      type: :string,
      description: "Path to the GitHub JSON file",
      default: "repos/github.json"
    },
    hexpm_path: %{
      type: :string,
      description: "Path to the Hex.pm JSON file",
      default: "repos/hexpm.json"
    },
    output_path: %{type: :string, description: "Output file path", default: "repos/merged.json"},
    hexpm_only_path: %{
      type: :string,
      description: "Optional path to write projects only found in Hex.pm",
      default: "repos/hexpm_only.json"
    }
  ]

  @github_scaling 34_000
  @hexpm_scaling 3_000_000

  def main(args) do
    case HelpfulOptions.parse(args, switches: @switches) do
      {:ok, parsed, []} ->
        run(parsed)

      {:error, reason} ->
        IO.puts("Invalid switches: #{inspect(reason)}")
        usage()
        System.halt(1)
    end
  end

  defp run(switches) do
    github_path = Map.get(switches, :github_path)
    hexpm_path = Map.get(switches, :hexpm_path)
    output_path = Map.get(switches, :output_path)
    hexpm_only_path = Map.get(switches, :hexpm_only_path)

    with {:ok, github_data} <- read_json(github_path),
         {:ok, hexpm_data} <- read_json(hexpm_path),
         {:ok, merged_data, hexpm_only} <- merge_and_sort(github_data, hexpm_data),
         :ok <- write_output(output_path, merged_data),
         :ok <- write_output(hexpm_only_path, hexpm_only) do
      IO.puts("Successfully wrote merged data to #{output_path}")
      :ok
    else
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        System.halt(1)
    end
  end

  defp read_json(path) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, "Failed to decode JSON from #{path}: #{reason}"}
        end

      {:error, reason} ->
        {:error, "Failed to read file #{path}: #{reason}"}
    end
  end

  defp merge_and_sort(github_data, hexpm_data) do
    hexpm_map =
      hexpm_data
      |> Enum.map(fn project -> {project["name"], project} end)
      |> Enum.into(%{})

    {both, hexpm_unmatched} =
      Enum.reduce(
        github_data,
        {[], hexpm_map},
        fn github_repo, {results, hexpm_unmatched} ->
          {hexpm_info, hexpm_unmatched} = Map.pop(hexpm_unmatched, github_repo["name"])

          if hexpm_info do
            if hexpm_info["repo_url"] != github_repo["url"] do
              IO.puts(
                "Warning: URL mismatch for #{github_repo["name"]}: " <>
                  "GitHub URL is #{github_repo["url"]}, but Hex.pm URL is #{hexpm_info["repo_url"]}"
              )
            end
          end

          merged = Map.merge(github_repo, hexpm_info || %{})

          sort_key =
            Map.get(merged, "stars", 0) / @github_scaling +
              Map.get(merged, "recent_downloads", 0) / @hexpm_scaling

          result = Map.put(merged, "sort_key", sort_key)
          {[result | results], hexpm_unmatched}
        end
      )

    hexpm_only =
      hexpm_unmatched
      |> Map.values()
      |> Enum.sort_by(fn project -> Map.get(project, "recent_downloads", 0) end, :desc)

    IO.puts(
      "Found #{length(both)} projects in both sources, and #{length(hexpm_only)} only in Hex.pm"
    )

    sorted = Enum.sort_by(both, fn item -> item["sort_key"] end, :desc)

    {:ok, sorted, hexpm_only}
  end

  defp write_output(path, data) do
    with {:ok, iodata} <- Jason.encode_to_iodata(data, pretty: true),
         :ok <- write_json(path, iodata) do
      :ok
    end
  end

  defp write_json(path, iodata) do
    case File.write(path, iodata) do
      :ok -> :ok
      {:error, reason} -> {:error, "Failed to write file #{path}: #{reason}"}
    end
  end

  defp usage() do
    IO.puts("""
    Usage: merge_sources [options]

    Options:
    --github-path PATH   Path to the GitHub JSON file (default: repos/github.json)
    --hexpm-path PATH   Path to the Hex.pm JSON file (default: repos/hexpm.json)
    --output-path PATH  Output file path (default: repos/merged.json)
    """)
  end
end

GreenValidation.MergeSources.main(System.argv())
