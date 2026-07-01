<title>Build the comparison</title>

<description>
Plans 0004–0007 each produce one per-source artifact under `style_sources/sources/`
(`mix_format.json`, `lexmag.json`, `credo.json`, `christopher_adams.json`), each keyed by
master rule id. This final plan joins them over the master list (plan 0003) into a single
comparison showing which rule is proposed by which source — the "group equivalent rules"
step, where the shared master id *is* the grouping. The result,
`style_sources/comparison.json`, is the deliverable for the whole series.

Because a source whose artifact is missing is reported as absent for every rule, the
command produces useful partial output before all of 0004–0007 are complete, which
supports the iterate-and-re-run workflow.
</description>

<branch>0008_build_comparison</branch>

<overview>
- `GreenValidation.StyleComparison.build/1` — takes the parsed per-source artifacts
  (decoupled from the filesystem for testability) and returns the comparison by iterating
  the master list (one row per master rule), joining each source's verdict:
  ```
  { "generated_with": {…}, "sources": [{id,name,repo_url}…],
    "rules": [ { "id", "title", "category",
                 "proposed_by": [...],
                 "sources": { "<id>": { "proposed", "reference" }, … } } ] }
  ```
  Validates every artifact rule id is a known master id (`StyleCatalog.valid_id?/1`);
  reports master rules that **no** source proposes (possible spurious/mis-named entry —
  the refinement loop in the opposite direction to the analyzers' `unmapped`).
- `mix green_validation.compare_styles` — thin Mix task → CLI module (pattern of
  `merge_sources`): reads `style_sources/sources/*.json`, calls `build/1`, writes
  `style_sources/comparison.json` (switches `--output-path`, `--sources-path`).
</overview>

<tasks>
- [ ] Write `test/green_validation/style_comparison_test.exs`: over fixture artifacts —
  one row per master rule; `proposed_by` matches the per-source map; missing source
  reported absent; unknown id rejected; no-proposer rules flagged. (red)
- [ ] Write `test/green_validation/cli/compare_styles_test.exs`: given fixture
  `sources/*.json` under `:tmp_dir`, writes a valid `comparison.json` that parses with one
  entry per master rule. (red)
- [ ] Implement `StyleComparison`. (green)
- [ ] Implement `CLI.CompareStyles` + Mix task. (green)
- [ ] With 0004–0007 run, run `compare_styles` and review `comparison.json`.
</tasks>

<principal_files>
- `lib/green_validation/style_comparison.ex` (new).
- `lib/green_validation/cli/compare_styles.ex` (new), `lib/mix/tasks/compare_styles.ex` (new).
- `style_sources/comparison.json` (output); `style_sources/sources/*.json` (inputs from 0004–0007).
- Tests: `test/green_validation/style_comparison_test.exs`,
  `test/green_validation/cli/compare_styles_test.exs`.
</principal_files>

<acceptance_criteria>
- [ ] `mix test` passes.
- [ ] `mix green_validation.compare_styles` writes a parseable
  `style_sources/comparison.json` with one entry per master rule.
- [ ] Formatter-enforced rules show `mix_format.proposed: true`; formatter-ignored rules `false`.
- [ ] Each prose-guide `proposed: true` entry has a working anchor URL into its vendored guide.
- [ ] `proposed_by` matches the per-source `sources` map; no-proposer master rules are reported.
- [ ] Runs (with partial output) against whatever subset of source artifacts is present.
</acceptance_criteria>
