# Create GitHub Repository Scraper Script

Status: [x]

## Description

Create an Elixir script that queries GitHub's REST API to download the URLs of all Elixir repositories, sorted by stars in descending order. The script should handle pagination and save the results to a file for later use.

## Technical Specifics

- Create script in `bin/` directory (e.g., `bin/gh_repos`)
- Use `Mix.install` for dependencies (like `bin/validate`)
- Install dependencies: `req`, `jason`, `helpful_options`
- Use `helpful_options` to parse CLI parameters (e.g., `--output-path`)
- Use `req` HTTP client library for REST API calls
- Use GitHub's REST API v3 search endpoint: `https://api.github.com/search/repositories?q=language:elixir&sort=stars&order=desc`
- Implement pagination by parsing the `link` HTTP response header
- Extract next page URL from link header (e.g., `link: <https://api.github.com/search/repositories?q=language%3Aelixir&sort=stars&order=desc&page=2>; rel="next"`)
- Continue fetching pages until no `rel="next"` link is present
- No authentication required (public API access)
- Output format: JSON list of repository URLs with metadata (stars, name, owner)
- Default output path with option to override via `--output-path` parameter
- Make script executable with proper shebang (`#!/usr/bin/env elixir`)

# Scrape hex.pm Package Data

Status: [x]

## Description

Fetch package information from hex.pm's API including names, recent downloads, descriptions, and repository URLs. Output the data as JSON.

## Technical Specifics

- API endpoint: https://hex.pm/api/packages?sort=downloads
- Returns 100 items (no pagination required)
- Extract from each item:
  - `name`
  - `recent_downloads` from `downloads.recent`
  - `description` from `meta.description`
  - `repo_url` from `meta.links.GitHub`
- Output format: Pretty-printed JSON file
- Default output location: `repos/hexpm.json`
- Implementation guide: Use [bin/github_repos](bin/github_repos) as a reference for structure and approach
