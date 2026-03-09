#!/usr/bin/env elixir

# Script to fetch Elixir repositories from GitHub sorted by stars
# We also add 12 repos that, while they have few stars on GitHub, have a lot of donwloads
# on hex.pm

Mix.install([
  {:green_validation, path: __DIR__ |> Path.join("..") |> Path.expand()},
  {:helpful_options, "~> 0.4.4"},
  {:jason, "~> 1.4"},
  {:req, "~> 0.5.17"}
])

defmodule GreenValidation.GithubRepos do
  @moduledoc """
  CLI tool to fetch Elixir repositories from GitHub sorted by stars.
  """

  alias GreenValidation.Github.Client

  @program "bin/github_repos"
  @default_output_path "repos/github.json"

  @commands [
    %{
      commands: [],
      description: "Fetch Elixir repositories from GitHub sorted by stars",
      switches: [
        output_path: %{
          type: :string,
          description: "Output file path (default: #{@default_output_path})"
        },
        limit: %{type: :integer, description: "Number of repositories to fetch (default: 100)"}
      ]
    }
  ]

  # These repos have few GitHub stars, but have a lot of downloads on hex.pm
  # The GitHub rate limit is 60 requests/hour, so a single run of this script will stay below that
  @low_star_additions [
    "beam-telemetry/telemetry",
    "elixir-plug/mime",
    "elixir-plug/plug_crypto",
    "falood/file_system",
    "elixir-mint/castore",
    "rrrene/bunt",
    "elixir-plug/plug_cowboy",
    "lau/tzdata",
    "christhekeele/erlex",
    "elixir-makeup/makeup_elixir",
    "ex-aws/ex_aws_s3",
    "getsentry/sentry-elixir"
  ]

  def main(args) do
    case HelpfulOptions.parse_commands(args, @commands) do
      {:ok, parsed} ->
        run(parsed)

      {:error, reason} ->
        IO.puts("Invalid command: #{inspect(reason)}")
        usage()
        System.halt(1)
    end
  end

  defp run(%{switches: switches}) do
    output_path = Map.get(switches, :output_path, @default_output_path)
    limit = Map.get(switches, :limit, 100)

    IO.puts("Fetching #{limit} Elixir repositories from GitHub...")

    with {:ok, response} <- fetch_repositories_by_stars(limit),
         {:ok, formatted_data} <- format_repositories(response),
         {:ok, low_star_additions} <- fetch_low_star_additions(),
         formatted_data = formatted_data ++ low_star_additions,
         :ok <- write_output(output_path, formatted_data) do
      IO.puts("Successfully wrote #{length(formatted_data)} repositories to #{output_path}")
      :ok
    else
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        System.halt(1)
    end
  end

  defp usage() do
    IO.puts("Usage:\n")
    IO.puts(HelpfulOptions.help_commands!(@program, @commands))
  end

  defp fetch_repositories_by_stars(limit) do
    search_query = Client.encode_search(language: "elixir")
    params = %{"q" => search_query, "sort" => "stars", "order" => "desc", "per_page" => 100}

    Client.get_paginated("/search/repositories", params, limit: limit)
  end

  defp format_repositories(%Req.Response{body: %{"items" => items}}) do
    formatted = Enum.map(items, &format_repository/1)

    {:ok, formatted}
  end

  defp fetch_low_star_additions() do
    results =
      @low_star_additions
      |> Enum.map(&fetch_repository/1)
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, repo} -> format_repository(repo) end)

    {:ok, results}
  end

  defp fetch_repository(owner_and_repo) do
    path = "repos/#{owner_and_repo}"

    case Client.get(path) do
      {:ok, %Req.Response{body: repo}} ->
        {:ok, repo}

      {:error, reason} ->
        {:error, "Failed to fetch repository at #{path}: #{reason}"}
    end
  end

  defp format_repository(repo) do
    %{
      name: repo["name"],
      owner: repo["owner"]["login"],
      url: repo["html_url"],
      stars: repo["stargazers_count"]
    }
  end

  defp write_output(output_path, data) do
    # Ensure the output directory exists
    output_path
    |> Path.dirname()
    |> File.mkdir_p!()

    case Jason.encode(data, pretty: true) do
      {:ok, json} ->
        File.write(output_path, json)

      {:error, reason} ->
        {:error, "Failed to encode JSON: #{inspect(reason)}"}
    end
  end
end

GreenValidation.GithubRepos.main(System.argv())
