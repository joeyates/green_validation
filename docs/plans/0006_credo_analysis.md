<title>Credo guide analysis</title>

<description>
Credo's guide (https://github.com/rrrene/elixir-style-guide) is the basis for Credo's
checks but presents rules as prose. We reuse the `GuideAnalyzer` / `CLI.AnalyzeGuide`
machinery built in plan 0005 and supply Credo's curated `[{master_id, anchor}]` mapping.
The guide markdown is already vendored by `fetch_style_guides`
(`style_sources/guides/credo.md`). This plan is largely curation/data entry on top of the
existing infrastructure. If curating Credo surfaces a rule with no master id, that is the
refinement loop working: add it to `StyleCatalog` (0003) first, then map it here.
</description>

<branch>0006_credo_analysis</branch>

<overview>
- `GreenValidation.Sources.Credo` — curated `[{master_id, anchor}]` mapping for Credo's
  guide; sections cover Code Readability, Naming, Sigils, Regular Expressions,
  Documentation, Refactoring, Software Design, Pitfalls. Every `master_id` must be a valid
  `StyleCatalog` id.
- `mix green_validation.analyze_credo` — thin Mix task delegating to the shared
  `CLI.AnalyzeGuide`; writes `style_sources/sources/credo.json`.
</overview>

<tasks>
- [ ] Write `test/green_validation/sources/credo_test.exs`: the Credo mapping references
  only valid master ids. (red)
- [ ] Write `test/green_validation/cli/analyze_credo_test.exs`: given a vendored `credo.md`
  under `:tmp_dir`, the command writes a valid `credo.json` that parses. (red)
- [ ] Implement `Sources.Credo` + `Mix.Tasks.GreenValidation.AnalyzeCredo`. (green)
- [ ] Run `fetch_style_guides` (if needed) then `analyze_credo`; review the artifact + `unmapped`.
</tasks>

<principal_files>
- `lib/green_validation/sources/credo.ex` (new), `lib/mix/tasks/analyze_credo.ex` (new).
- `style_sources/sources/credo.json` (output); `style_sources/guides/credo.md` (input, vendored by 0005).
- Tests: `test/green_validation/sources/credo_test.exs`, `test/green_validation/cli/analyze_credo_test.exs`.
</principal_files>

<acceptance_criteria>
- [ ] `mix test` passes.
- [ ] `mix green_validation.analyze_credo` writes a parseable `style_sources/sources/credo.json`.
- [ ] `proposed: true` anchors resolve into `guides/credo.md`.
- [ ] The Credo mapping references only valid `StyleCatalog` ids.
- [ ] `unmapped` lists guide sections not yet covered by the master list.
</acceptance_criteria>
