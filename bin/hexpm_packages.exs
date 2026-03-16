#!/usr/bin/env elixir

# Script to fetch package information from hex.pm

Mix.install(
  [
    {:green, "~> 0.1.10"},
    {:green_validation, path: __DIR__ |> Path.join("..") |> Path.expand()},
    {:helpful_options, "~> 0.4.4"},
    {:jason, "~> 1.4"},
    {:req, "~> 0.5.17"}
  ],
  consolidate_protocols: false
)

defmodule GreenValidation.HexpmPackages do
  @moduledoc """
  CLI tool to fetch package information from hex.pm sorted by downloads.
  """

  alias GreenValidation.Hexpm.Package

  require Logger

  @program "bin/hexpm_packages"
  @default_output_path "repos/hexpm.json"

  @commands [
    %{
      commands: [],
      description: "Fetch package information from hex.pm sorted by downloads",
      switches: [
        output_path: %{
          type: :string,
          description: "Output file path (default: #{@default_output_path})"
        },
        verbose: %{type: :boolean, description: "Print names of packages without a repo_url"}
      ]
    }
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
    verbose = Map.get(switches, :verbose, false)

    Logger.info("Fetching package information from hex.pm...")

    with {:ok, response} <- fetch_packages(),
         {:ok, formatted_data} <- to_packages(response, verbose),
         :ok <- write_output(output_path, formatted_data) do
      Logger.info("Successfully wrote #{length(formatted_data)} packages to #{output_path}")
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
    """
  end

  defp fetch_packages() do
    url = "https://hex.pm/api/packages"
    params = %{"sort" => "downloads"}

    case Req.get(url, params: params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP request failed with status #{status}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp to_packages(packages, verbose) when is_list(packages) do
    formatted =
      packages
      |> Enum.map(fn package ->
        %Package{
          name: package["name"],
          recent_downloads: get_in(package, ["downloads", "recent"]),
          description: get_in(package, ["meta", "description"]),
          repo_url: get_in(package, ["meta", "links", "GitHub"])
        }
      end)
      |> optionally_list_repos_without_repo_url(verbose)
      |> Enum.filter(fn package -> package.repo_url != nil end)

    {:ok, formatted}
  end

  defp to_packages(_, _), do: {:error, "Invalid response format"}

  defp optionally_list_repos_without_repo_url(packages, true) do
    Enum.each(packages, fn package ->
      if package.repo_url == nil do
        Logger.info("Package without repo_url: #{package.name}")
      end
    end)

    packages
  end

  defp optionally_list_repos_without_repo_url(packages, false), do: packages

  defp write_output(output_path, data) do
    # Ensure the output directory exists
    case output_path |> Path.dirname() |> File.mkdir_p() do
      :ok ->
        write_json(output_path, data)

      {:error, reason} ->
        {:error, "Failed to create output directory: #{inspect(reason)}"}
    end
  end

  defp write_json(output_path, data) do
    with {:ok, json} <- Jason.encode(data, pretty: true),
         :ok <- File.write(output_path, json) do
      :ok
    else
      {:error, reason} ->
        {:error, "Failed to save JSON file: #{inspect(reason)}"}
    end
  end
end

GreenValidation.HexpmPackages.main(System.argv())
