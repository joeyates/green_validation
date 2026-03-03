---
title: Create GitHub Repository Scraper Script
description: Create an Elixir script that queries GitHub's REST API to download Elixir repositories sorted by stars
branch: feature/github-scraper-script
---

## Overview

Create a standalone executable script `bin/github_repos` that leverages the existing `GreenValidation.Github.Client` module to fetch Elixir repositories from GitHub's API, sorted by stars. The script will handle pagination automatically and save results to a JSON file.

## Tasks

- [x] Create `bin/github_repos` script with proper shebang and Mix.install
- [x] Implement CLI module with helpful_options for parameter parsing (`--output-path`, `--limit`)
- [x] Use existing `GreenValidation.Github.Client.get_paginated/3` to fetch repositories
- [x] Extract and format repository data (URL, name, owner, stars) from API response
- [x] Write formatted JSON output to file (default: `results/github_repos.json`)
- [x] Make script executable
- [x] Address any additional implementation details that arise during development
- [x] Mark the plan as "done"

## Principal Files

- `bin/github_repos` (new) - Main script file
- `lib/green_validation/github/client.ex` - Existing GitHub API client with pagination
- `lib/green_validation/github/paginated_accumulator.ex` - Supporting pagination logic
- `mix.exs` - Reference for dependency versions

## Acceptance Criteria

- Script is executable from command line: `bin/github_repos`
- Mix.install uses dependency versions matching `mix.exs` (req ~> 0.5.17, jason ~> 1.4, helpful_options ~> 0.4.4)
- Accepts `--output-path` parameter to override default output location
- Accepts `--limit` parameter to control number of repositories fetched (default: 100)
- Uses existing `GreenValidation.Github.Client.get_paginated/3` for API calls
- Outputs valid JSON with repository data including: name, owner, URL, stars count
- Handles errors gracefully (API failures, file write errors)
- Follows same structure and patterns as existing `bin/validate` script
