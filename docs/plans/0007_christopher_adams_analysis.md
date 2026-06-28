<title>The Elixir Style Guide (christopheradams) analysis</title>

<description>
The Elixir Style Guide (https://github.com/christopheradams/elixir_style_guide) is the
most widely cited community guide and is prose-structured. We reuse the `GuideAnalyzer` /
`CLI.AnalyzeGuide` machinery from plan 0005 and supply this guide's curated
`[{master_id, anchor}]` mapping. The markdown is already vendored by `fetch_style_guides`
(`style_sources/guides/christopher_adams.md`). Largely curation/data entry. A rule found
while curating that has no master id is a refinement-loop signal: add it to `StyleCatalog`
(0003), then map it here.
</description>

<branch>0007_christopher_adams_analysis</branch>

<overview>
- `GreenValidation.Sources.ChristopherAdams` — curated `[{master_id, anchor}]` mapping;
  sections cover Formatting and The Guide (expressions, naming, comments, modules,
  documentation, typespecs, structs, exceptions, collections, strings, metaprogramming,
  testing). Every `master_id` must be a valid `StyleCatalog` id.
- `mix green_validation.analyze_christopher_adams` — thin Mix task delegating to the
  shared `CLI.AnalyzeGuide`; writes `style_sources/sources/christopher_adams.json`.
</overview>

<tasks>
- [ ] Write `test/green_validation/sources/christopher_adams_test.exs`: the mapping
  references only valid master ids. (red)
- [ ] Write `test/green_validation/cli/analyze_christopher_adams_test.exs`: given a
  vendored markdown under `:tmp_dir`, the command writes a valid artifact that parses. (red)
- [ ] Implement `Sources.ChristopherAdams` + `Mix.Tasks.GreenValidation.AnalyzeChristopherAdams`. (green)
- [ ] Run `fetch_style_guides` (if needed) then `analyze_christopher_adams`; review the
  artifact + `unmapped`.
</tasks>

<principal_files>
- `lib/green_validation/sources/christopher_adams.ex` (new),
  `lib/mix/tasks/analyze_christopher_adams.ex` (new).
- `style_sources/sources/christopher_adams.json` (output);
  `style_sources/guides/christopher_adams.md` (input, vendored by 0005).
- Tests: `test/green_validation/sources/christopher_adams_test.exs`,
  `test/green_validation/cli/analyze_christopher_adams_test.exs`.
</principal_files>

<acceptance_criteria>
- [ ] `mix test` passes.
- [ ] `mix green_validation.analyze_christopher_adams` writes a parseable
  `style_sources/sources/christopher_adams.json`.
- [ ] `proposed: true` anchors resolve into `guides/christopher_adams.md`.
- [ ] The mapping references only valid `StyleCatalog` ids.
- [ ] `unmapped` lists guide sections not yet covered by the master list.
</acceptance_criteria>
