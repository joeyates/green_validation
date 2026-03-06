---
title: Scrape hex.pm Package Data
description: Create a script to fetch package information from hex.pm's API including names, recent downloads, descriptions, and repository URLs, outputting the data as JSON.
branch: feature/scrape-hexpm-package-data
---

## Overview

Create an Elixir script at `bin/hexpm_packages` that fetches the top 100 packages from hex.pm's public API sorted by downloads. The script will extract package name, recent downloads, description, and GitHub repository URL, then output the data as pretty-printed JSON to `repos/hexpm.json`.

## Tasks

- [x] Create executable script `bin/hexpm_packages` with proper shebang
- [x] Set up Mix.install with dependencies (req, jason, helpful_options, green_validation)
- [x] Define CLI interface with HelpfulOptions for `--output-path` parameter
- [x] Implement API fetch function to call `https://hex.pm/api/packages?sort=downloads`
- [x] Parse response and extract required fields (name, recent_downloads from downloads.recent, description from meta.description, repo_url from meta.links.GitHub)
- [x] Format extracted data into structured maps
- [x] Implement JSON output writer with pretty printing to default path `repos/hexpm.json`
- [x] Add error handling for API failures and JSON encoding errors
- [x] Make the script executable
- [ ] Address any additional implementation details that arise during development
- [ ] Mark the plan as "done"

## Principal Files

- `bin/hexpm_packages` (new) - Main script file
- `bin/github_repos` (reference) - Reference implementation
- `repos/hexpm.json` (new) - Output file

## Acceptance Criteria

- Script executes successfully and fetches data from hex.pm API
- Output file contains 100 packages with all required fields (name, recent_downloads, description, repo_url)
- JSON output is properly formatted (pretty-printed)
- Script accepts `--output-path` parameter to override default output location
- Script provides clear user feedback during execution
- Error conditions are handled gracefully with appropriate messages
