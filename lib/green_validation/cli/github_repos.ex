defmodule GreenValidation.CLI.GithubRepos do
  @moduledoc """
  Fetches Elixir repositories from GitHub sorted by stars.

  We also add 12 repos that, while they have few stars on GitHub, have a lot of downloads
  on hex.pm
  """

  alias GreenValidation.Github.{Client, Repo}

  require Logger

  @program "bin/github_repos.exs"
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

  @skip [
    # magnetissimo uses an old Erlang+Elixir combination and old dependencies.
    # Unable to compile
    "magnetissimo",
    # Failed to compile asciinema-server. Requires Rust, but .tool-versions doesn't specify
    # a Rust version
    "asciinema-server",
    # elixirscript seems abandoned
    "elixirscript",
    # 'mix compile' fails
    "bors-ng"
  ]

  # These repos have few GitHub stars, but have a lot of downloads on hex.pm
  # The GitHub rate limit is 60 requests/hour, so a single run of this script will stay below that
  @low_star_additions [
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
        Logger.info("Invalid command: #{inspect(reason)}")
        usage()
        System.halt(1)
    end
  end

  defp run(%{switches: switches}) do
    output_path = Map.get(switches, :output_path, @default_output_path)
    limit = Map.get(switches, :limit, 100)

    Logger.info("Fetching #{limit} Elixir repositories from GitHub...")

    with {:ok, response} <- fetch_repositories_by_stars(limit),
         {:ok, repos} <- format_repositories(response),
         {:ok, low_star_additions} <- fetch_low_star_additions(),
         repos = repos ++ low_star_additions,
         repos = Enum.reject(repos, &(&1.name in @skip)),
         :ok <- write_output(output_path, repos) do
      Logger.info("Successfully wrote #{length(repos)} repositories to #{output_path}")
      :ok
    else
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

  defp fetch_repositories_by_stars(limit) do
    search_query = Client.encode_search(language: "elixir")
    params = %{"q" => search_query, "sort" => "stars", "order" => "desc", "per_page" => 100}

    Client.get_paginated("/search/repositories", params, limit: limit)
  end

  defp format_repositories(%Req.Response{body: %{"items" => items}}) do
    formatted = Enum.map(items, &to_repo/1)

    {:ok, formatted}
  end

  defp fetch_low_star_additions() do
    results =
      @low_star_additions
      |> Enum.map(&fetch_repository/1)
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, repo} -> to_repo(repo) end)

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

  defp to_repo(repo) do
    %Repo{
      default_branch: repo["default_branch"],
      name: repo["name"],
      owner: repo["owner"]["login"],
      url: repo["html_url"],
      stars: repo["stargazers_count"]
    }
  end

  defp write_output(output_path, repos) do
    # Ensure the output directory exists
    output_path
    |> Path.dirname()
    |> File.mkdir_p!()

    case Jason.encode(repos, pretty: true) do
      {:ok, json} ->
        File.write(output_path, json)

      {:error, reason} ->
        {:error, "Failed to encode JSON: #{inspect(reason)}"}
    end
  end
end
