# Green Formatter Validation System

This validation system tests Green's formatter implementation against major Elixir projects to identify which rules are triggered and ensure formatter stability.

## Overview

The validation system:
1. Clones major Elixir open-source projects at their latest stable releases
2. Runs baseline formatting checks to verify projects are already formatted
3. Tests each Green rule individually to isolate which rules trigger changes
4. Captures detailed results as JSON with line-level granularity
5. Generates aggregate statistics across all projects

## Prerequisites

The validation system requires Green to be available when running `mix format` in target projects. Currently, you need to manually add Green as a dependency to each cloned project, or use the GreenInstaller module helper functions.

### Manual Setup (Simple)

After cloning a project, add Green to its `mix.exs`:

```elixir
defp deps do
  [
    # Use path dependency to test local changes
    {:green, path: "/path/to/green", override: true}
    # Or use published version
    # {:green, "~> 0.1.10"}
  ]
end
```

Then run `mix deps.get` in the project directory.

### Automated Setup (Recommended)

The validation system includes a `GreenInstaller` module that can automatically:
- Add Green as a path dependency to test local changes
- Modify .formatter.exs to enable Green plugins
- Install dependencies
- Restore original files after validation

This integration is planned for future automation.

## Quick Start

### 1. Clone Projects

Clone all target projects:
```bash
bin/validate clone
```

Or clone a specific project:
```bash
bin/validate clone phoenix
```

**Target Projects:**
- elixir (Elixir language monorepo)
- phoenix (Phoenix web framework)
- phoenix_live_view (Phoenix LiveView)
- hexpm (Hex package manager)
- nerves (Nerves embedded framework)
- absinthe (Absinthe GraphQL)
- broadway (Broadway data processing)
- credo (Credo static analysis)

### 2. Run Validation

Run full validation (baseline + per-rule checks) for all projects:
```bash
bin/validate validate
```

Or validate a specific project:
```bash
bin/validate validate phoenix
```

This will:
- Check baseline formatting (without Green)
- Test each Green rule individually
- Save results as JSON in `results/` directory

### 3. Generate Summary Report

View aggregate statistics across all validation results:
```bash
bin/validate summary
```

This displays:
- Overall statistics (projects, targets, rules tested)
- Baseline formatting compliance rates
- Most commonly triggered rules
- Per-project summaries

## Available Commands

### Repository Management

```bash
# Clone all repositories
bin/validate clone

# Clone a specific project
bin/validate clone <project_name>
```

### Inspection Commands

```bash
# Detect subprojects in monorepos
bin/validate detect

# Detect subprojects in a specific repo
bin/validate detect <project_name>
```

### Testing Commands

```bash
# Check baseline formatting (without Green) for all projects
bin/validate baseline

# Check baseline for a specific project
bin/validate baseline <project_name>

# Validate each rule individually for all projects
bin/validate rules

# Validate rules for a specific project
bin/validate rules <project_name>
```

### Full Validation

```bash
# Run complete validation and save JSON results
bin/validate validate

# Validate a specific project only
bin/validate validate <project_name>
```

### Reporting

```bash
# Generate aggregate summary from all results
bin/validate summary
```

## Understanding Results

### JSON Result Schema

Each validation run creates a JSON file in `results/` with the following structure:

```json
{
  "metadata": {
    "project": "project_name",
    "repository": "https://github.com/...",
    "commit_sha": "abc123...",
    "tag_or_branch": "v1.0.0",
    "green_version": "0.1.10",
    "validated_at": "2026-02-24T10:00:00Z",
    "target_name": "lib_elixir",
    "target_path": "/path/to/target"
  },
  "baseline": {
    "clean": true,
    "files_needing_formatting": 0
  },
  "rules": [
    {
      "rule": "avoid_needless_pipelines",
      "files_affected": 2,
      "total_changes": 5,
      "files": [
        {
          "path": "lib/example.ex",
          "lines": [10, 25, 30]
        }
      ]
    }
  ]
}
```

### Result Files

Results are saved with timestamped filenames:
- Format: `{project_name}_{YYYYMMDDTHHmmss}.json`
- Example: `phoenix_20260224T103045.json`
- Location: `test/projects/validation/results/`

### Summary Report

The summary report shows:

1. **Overview**: Total projects, targets, and rules tested
2. **Baseline Formatting**: How many projects are already clean
3. **Rule Statistics**: Top triggered rules with counts
4. **Per-Project Results**: Individual project compliance

## Interpreting Results

### Baseline Status

- **Clean**: Project is already formatted correctly (no changes needed)
- **Needs Formatting**: Some files don't match standard Elixir formatter

A clean baseline means the project follows standard Elixir formatting conventions.

### Rule Results

For each rule:
- **files_affected**: Number of files that would be changed by this rule
- **total_changes**: Total line-level changes across all files
- **files**: Detailed list of affected files and line numbers

### Common Scenarios

**High files_affected count**: The rule triggers frequently in real projects. May indicate:
- A common pattern that violates the style guide
- Potential incompatibility with Elixir's standard formatter
- A rule that may need refinement

**Zero files_affected**: The rule never triggers. May indicate:
- Projects already follow this guideline
- The rule is too specific or unusual
- Potential bug in rule implementation

**Baseline failures**: If many projects fail baseline checks:
- They may not be using `mix format` consistently
- May need to update to latest versions
- Could indicate formatter compatibility issues

## Workflow for Green Development

### 1. Initial Validation

Run validation to establish baseline:

```bash
bin/validate clone
bin/validate validate
bin/validate summary
```

### 2. After Rule Changes

When modifying Green rules, re-run validation:
```bash
bin/validate validate
bin/validate summary
```

Compare results to previous runs to see impact of changes.

### 3. Investigating Issues

To investigate a specific rule on a specific project:
```bash
# Test only that project
bin/validate validate phoenix

# Check the JSON result for detailed file/line information
cat results/phoenix_*.json | grep -A 20 '"rule": "problematic_rule"'
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
