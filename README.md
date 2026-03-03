# Green Formatter Validation

Do a survey of the formatting status of the most popular Elixir projects

This validation system tests Green's formatter implementation against major Elixir projects to identify which rules are triggered and ensure formatter stability.

## Overview

The validation system:
1. Clones major Elixir open-source projects at their latest stable releases
2. Runs baseline formatting checks to verify projects are already formatted
3. Tests each Green rule individually to isolate which rules trigger changes
4. Captures detailed results as JSON with line-level granularity
5. Generates aggregate statistics across all projects

## Setup

The validation system includes a `GreenInstaller` module that can automatically:
- Add Green as a path dependency to test local changes
- Modify .formatter.exs to enable Green plugins
- Install dependencies
- Restore original files after validation

## Quick Start

The validation system automatically clones projects when they're not present.

**Target Repositories and projects:**
- elixir (Elixir language monorepo): elixir, eex, ex_unit, iex, logger and mix projects,
- phoenix (Phoenix web framework)
- phoenix_live_view (Phoenix LiveView)
- hexpm (Hex package manager)
- nerves (Nerves embedded framework)
- absinthe (Absinthe GraphQL)
- broadway (Broadway data processing)
- credo (Credo static analysis)

### Run Validation

Check all projects:
```bash
bin/validate check
```

Or check a specific project:
```bash
bin/validate check phoenix
```

This will:
- Clone repositories if not already cloned
- Check baseline formatting (creating a format commit if needed)
- Test each Green rule individually
- Print results to stdout

### Export Results to File

You can save validation results to a file using the `--format` option:

```bash
# Save results as JSON
bin/validate check --format json
bin/validate check phoenix --format json

# Save results as formatted text
bin/validate check --format text
bin/validate check phoenix --format text
```

Output files are automatically named using the commit SHA and saved to the `results` directory:
- JSON: `validation_<project>_<commit-sha>.json`
- Text: `validation_<project>_<commit-sha>.txt`
- Example: `validation_phoenix_abc123de.json`

## Available Commands

### Validation Commands

```bash
# Check all projects (prints to stdout)
bin/validate check

# Check a specific project
bin/validate check <project_name>

# Check with JSON output to file
bin/validate check --format json
bin/validate check <project_name> --format json

# Check with text output to file  
bin/validate check --format text
bin/validate check <project_name> --format text
```

### Help

```bash
# Show all available commands and options
bin/validate help
```

## Understanding Results

### JSON Result Schema

When using `--format json`, each validation creates a JSON file with the following structure:

```json
{
  "test_run": {
    "project_name": "phoenix",
    "repository": "https://github.com/phoenixframework/phoenix",
    "commit_sha": "abc123def456...",
    "branch": "main",
    "green_version": "0.1.10"
  },
  "baseline": "clean",
  "rules": [
    {
      "rule": "avoid_needless_pipelines",
      "changes": [
        "lib/phoenix/endpoint.ex",
        "lib/phoenix/router.ex"
      ],
      "warnings": []
    },
    {
      "rule": "prefer_pipelines",
      "changes": [],
      "warnings": [
        "test/phoenix/endpoint_test.exs"
      ]
    }
  ]
}
```

### Text Result Format

When using `--format text`, results are formatted as human-readable text with:
- Test run metadata (project, repository, commit, branch, Green version)
- Baseline status (clean or created formatting commit)
- Per-rule results showing files with changes and warnings
- Summary statistics (total rules, rules with changes, etc.)

### Result Files

Results are saved with filenames based on the commit SHA:
- Format: `validation_{project_name}_{commit_sha}.{ext}`
- Example: `validation_phoenix_abc123de.json`
- Location: `results/` directory

## Interpreting Results

### Baseline Status

- **`:clean`**: Project is already formatted correctly (no changes needed)
- **`:created_format_commit`**: Baseline formatting commit was created

A clean baseline means the project follows standard Elixir formatting conventions.

### Rule Results

For each rule:
- **changes**: List of files that would be changed by this rule
- **warnings**: List of files that trigger warnings but not changes

### Common Scenarios

**Many files in changes list**: The rule triggers frequently in real projects. May indicate:
- A common pattern that violates the style guide
- Potential incompatibility with Elixir's standard formatter
- A rule that may need refinement

**Empty changes and warnings**: The rule never triggers. May indicate:
- Projects already follow this guideline
- The rule is too specific or unusual
- Potential bug in rule implementation

**Baseline requires formatting commit**: If projects need baseline formatting:
- They may not be using `mix format` consistently
- May need to update to latest versions

## Workflow for Green Development

### 1. Initial Validation

Check all projects to establish baseline:

```bash
bin/validate check
```

### 2. Save Results for Analysis

Export results to JSON for detailed analysis:

```bash
bin/validate check --format json
bin/validate check phoenix --format json
```

### 3. After Rule Changes

When modifying Green rules, re-check to see impact:

```bash
bin/validate check --format json
```

Compare the new JSON results to previous runs to see what changed.

### 4. Investigating Specific Issues

Check a single project for faster iteration:

```bash
bin/validate check phoenix
```

## Directory Structure

```
test/projects/validation/
├── lib/                          # Validation modules
│   ├── baseline_checker.ex       # Baseline formatting checks
│   ├── diff_parser.ex            # Parse mix format output
│   ├── green_installer.ex        # Install Green in projects
│   ├── monorepo_detector.ex      # Detect subprojects
│   ├── repo_cloner.ex            # Clone repositories
│   ├── result_collector.ex       # Collect validation results
│   ├── result_writer.ex          # Write JSON results
│   ├── rule_validator.ex         # Per-rule validation
│   └── summary_reporter.ex       # Generate summaries
├── repos/                        # Cloned repositories (gitignored)
├── results/                      # JSON result files (gitignored)
├── validate.exs                  # Main CLI script
├── .gitignore                    # Ignore repos and results
└── README.md                     # This file
```

## Troubleshooting

### "No mix.exs found"

The project directory may not be set up correctly. Try:
```bash
cd repos/<project_name>
ls -la  # Verify mix.exs exists
```

### "Failed to clone"

Check network connectivity and GitHub access. The repository may have moved or been renamed.

### "No validation results found"

Make sure you've run validation first:
```bash
bin/validate validate
```

### JSON Parse Errors

If result files are corrupted, delete them and re-run validation:
```bash
rm results/*.json
bin/validate validate
```

## Updating Baselines

To test against new versions of projects:

1. Delete the cloned repository:

   ```bash
   rm -rf repos/<project_name>
   ```

2. Re-clone to get the latest stable release:

   ```bash
   bin/validate clone <project_name>
   ```

3. Re-run validation:

   ```bash
   bin/validate validate <project_name>
   ```

## Contributing

When adding new rules to Green:

1. Run validation before and after the change
2. Compare results to understand impact
3. Document any significant findings
4. Update rule documentation if patterns are common

## Technical Details

### Validation Process

For each target (project or subproject):

1. **Baseline Check**: Run `mix format --check-formatted` without Green
2. **Per-Rule Validation**: For each Green rule:
   - Create custom `.formatter.exs` with only that rule enabled
   - Run `mix format --check-formatted`
   - Parse diff output to extract affected files and lines
3. **Result Collection**: Combine baseline and per-rule results
4. **JSON Serialization**: Save complete results with metadata

### Rule Isolation

Each rule is tested individually by:
1. Disabling all other rules in `.formatter.exs`
2. Enabling only the target rule
3. Running formatter to see impact

This ensures we can precisely attribute changes to specific rules.

## Future Enhancements

Potential improvements:
- Automated regression testing (detect unexpected rule changes)
- Historical tracking (compare results over time)
- Web-based result viewer
- CI/CD integration
- Automatic issue detection and reporting

## Current Limitations

### Green Dependency Installation

The current implementation requires manual setup of Green in each target project. The `GreenInstaller` module exists but is not yet integrated into the automated workflow. To use the validation system:

1. Clone projects with `bin/validate clone`
2. Manually add Green as a dependency in each project's `mix.exs`
3. Run `mix deps.get` in each project
4. Then run validation with `bin/validate validate`

Future versions will automate this process.

### Error Recovery

If validation fails midway, manual cleanup may be needed:
- Check for `.backup` files in target projects
- Verify `mix.exs` and `.formatter.exs` are restored
- Remove temporary Green dependencies if added manually
