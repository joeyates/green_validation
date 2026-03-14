#!/usr/bin/env elixir

Mix.install(
  [
    {:green, "~> 0.1.10"},
    {:green_validation, path: __DIR__ |> Path.join("..") |> Path.expand()},
    {:helpful_options, "~> 0.4.4"},
    {:jason, "~> 1.4"}
  ],
  consolidate_protocols: false
)

defmodule GreenValidation.MergeSources do
  @moduledoc """
  CLI tool to merge and sort JSON files representing:
  1. the most starred Elixir repos on GitHub
  2. the most downloaded Projects on hex.pm
  """

  alias GreenValidation.Github.Repo
  alias GreenValidation.Hexpm.Package
  alias GreenValidation.Project

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

    with {:ok, github_data} <- read_github(github_path),
         {:ok, hexpm_data} <- read_hexpm(hexpm_path),
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

  defp read_github(path) do
    with {:ok, data} <- read_json(path),
         {:ok, repos} <- to_repos(data) do
      {:ok, repos}
    end
  end

  defp to_repos(data) do
    data
    |> Enum.map(&struct!(Repo, &1))
    |> then(&{:ok, &1})
  end

  defp read_hexpm(path) do
    with {:ok, data} <- read_json(path),
         {:ok, packages} <- to_packages(data) do
      {:ok, packages}
    end
  end

  defp to_packages(data) do
    data
    |> Enum.map(&struct!(Package, &1))
    |> then(&{:ok, &1})
  end

  defp read_json(path) do
    with {:ok, content} <- File.read(path),
         {:ok, data} <- Jason.decode(content, keys: :atoms) do
      {:ok, data}
    end
  end

  defp merge_and_sort(github_data, hexpm_data) do
    hexpm_map =
      hexpm_data
      |> Enum.map(fn package -> {package.name, package} end)
      |> Enum.into(%{})

    {both, hexpm_unmatched} =
      Enum.reduce(
        github_data,
        {[], hexpm_map},
        fn repo, {results, hexpm_unmatched} ->
          {package, hexpm_unmatched} = Map.pop(hexpm_unmatched, repo.name)

          recent_downloads =
            if package do
              if package.repo_url != repo.url do
                raise ArgumentError,
                      "Warning: URL mismatch for #{repo.name}: " <>
                        "GitHub URL is #{repo.url}, but Hex.pm URL is #{package.repo_url}"
              end

              package.recent_downloads
            else
              0
            end

          project =
            %Project{
              name: repo.name,
              url: repo.url,
              default_branch: repo.default_branch
            }

          sort_key = repo.stars / @github_scaling + recent_downloads / @hexpm_scaling

          result = {project, sort_key}
          {[result | results], hexpm_unmatched}
        end
      )

    hexpm_only =
      hexpm_unmatched
      |> Map.values()
      |> Enum.sort_by(& &1.recent_downloads, :desc)

    IO.puts(
      "Found #{length(both)} projects in both sources, and #{length(hexpm_only)} only in Hex.pm"
    )

    sorted =
      both
      |> Enum.sort_by(&elem(&1, 1), :desc)
      |> Enum.map(&elem(&1, 0))

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
