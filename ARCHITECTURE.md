# Architecture

## Validation flow

When running validations, from the command line through to the written report, the path is:

```
CLI → validation → report
```

## 1. CLI

The entry point is the Mix task `Mix.Tasks.GreenValidation.Validate`
(`lib/mix/tasks/validate.ex`), which simply forwards its arguments to
`GreenValidation.CLI.Validate.main/1` (`lib/green_validation/cli/validate.ex`).

`GreenValidation.CLI.Validate` is the orchestrator for the whole run:

- It parses the command and switches (via `HelpfulOptions`) and dispatches to one
  of `check-all`, `check-project`, or `setup-project`.
- It resolves the Green dependency to test against with
  `GreenValidation.GreenDependency` (a version tag or a local checkout path).
- It selects which rules to run from `GreenValidation.Rules`
  (`Rules.all/0`, or a single rule passed with `--rule`).
- It loads the target projects from `GreenValidation.Projects`
  (`Projects.all/0` for `check-all`, `Projects.load!/1` for a named project), each
  represented as a `GreenValidation.Project`.

For `check-all`, the CLI iterates every project; for `check-project` it runs a
single one. Both funnel into the private `check_project_rules/3`, which is the
boundary between the CLI and the validation phase.

## 2. Validation

For each project the CLI prepares the working copy and then validates the rules.

### Preparation

- `GreenValidation.Project.clone/1` produces a `GreenValidation.ClonedRepo`
  (checked out at a pinned commit). When `--format json` is used, the CLI can skip
  projects whose report already exists for that commit SHA (via
  `GreenValidation.ReportWriter.report_exists?/4`).
- `Project.install_deps/1` and `Project.compile/1` make the project buildable.
- `GreenValidation.BaselineFormatter.ensure_clean/1` runs the standard Elixir
  formatter first, so that any subsequent changes can be attributed to Green rules
  rather than pre-existing formatting drift. It reports a baseline status of
  `:clean` or `:created_format_commit`.

Projects with subprojects are fanned out: each `GreenValidation.Subproject` is
treated as a standalone project reusing the same cloned repository.

### Per-rule validation

`GreenValidation.RuleValidator.validate_rules/3`
(`lib/green_validation/rule_validator.ex`) is the heart of the validation phase:

- It installs Green into the project with `GreenValidation.GreenInstaller`
  (which edits `mix.exs` through `GreenValidation.Installer.MixExs`).
- For each rule it writes a custom `.formatter.exs` that enables **only** that rule
  and disables all others (`GreenValidation.Installer.FormatterExs`), isolating the
  rule's effect.
- It runs `mix format --check-formatted` (`Project.mix_command/2`) and hands the
  output to `GreenValidation.OutputParser`, which extracts the affected files as
  `GreenValidation.Change` and `GreenValidation.Warning` values, collected into a
  `GreenValidation.RuleResult`.
- After each rule, and after the whole run, it resets the files it modified.

### Result assembly

Back in the CLI, `build_test_run/3` builds a `GreenValidation.TestRun` holding the
run metadata (project name, repository, commit SHA, branch, Green version). The
test run, the baseline status, and the list of per-rule `RuleResult`s are combined
into a single `GreenValidation.Result`.

## 3. Report

The `GreenValidation.Result` is rendered for output:

- **stdout** — `print_results/2` in the CLI always prints a human-readable summary
  of each rule's changes and warnings.
- **files** — when `--format json` or `--format text` is given, the CLI calls
  `GreenValidation.ReportWriter.write/3` (`lib/green_validation/report_writer.ex`),
  which serializes the `Result` (JSON via `Jason`, or a formatted text report) and
  writes it to the `results/` directory.

Report filenames follow `validation_<project_slug>_<short_sha>.<ext>`, produced by
`ReportWriter.filename/3`. The same naming is what `report_exists?/4` uses earlier
to skip already-validated commits.

## Summary of the flow

| Phase      | Modules |
|------------|---------|
| CLI        | `Mix.Tasks.GreenValidation.Validate`, `GreenValidation.CLI.Validate`, `GreenValidation.Projects`, `GreenValidation.Project`, `GreenValidation.GreenDependency`, `GreenValidation.Rules` |
| Validation | `GreenValidation.ClonedRepo`, `GreenValidation.BaselineFormatter`, `GreenValidation.GreenInstaller`, `GreenValidation.Installer.MixExs`, `GreenValidation.Installer.FormatterExs`, `GreenValidation.RuleValidator`, `GreenValidation.OutputParser` |
| Report     | `GreenValidation.Result`, `GreenValidation.RuleResult`, `GreenValidation.TestRun`, `GreenValidation.Change`, `GreenValidation.Warning`, `GreenValidation.ReportWriter` |
