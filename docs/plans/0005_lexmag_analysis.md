<title>Lexmag guide analysis (and shared guide machinery)</title>

<description>
Lexmag's guide (https://github.com/lexmag/elixir-style-guide) is prose with no
machine-readable rule list. We curate a mapping from master rule ids (plan 0003) to the
guide's section anchors, validate those anchors against a **vendored** copy of the guide
(reproducible, offline), and emit a per-source artifact for plan 0008 to merge.

All three prose guides (Lexmag, Credo, christopheradams) work identically, so this plan
also builds the reusable infrastructure once: a `fetch_style_guides` command that
downloads and vendors all three guides, a shared `GuideAnalyzer`, and a parameterised
`CLI.AnalyzeGuide`. Plans 0006 and 0007 then reuse them with just a mapping module and a
thin Mix task. Guide content is fetched and vendored so analysis runs offline against
pinned copies; fetching records each guide's commit SHA for provenance.
</description>

<branch>0005_lexmag_analysis</branch>

<overview>
Shared infrastructure (built here, reused by 0006/0007):
- `mix green_validation.fetch_style_guides` — uses `Req` (as
  `lib/green_validation/github/client.ex` does) to vendor all three guides to
  `style_sources/guides/{lexmag,credo,christopher_adams}.md` and record SHAs/URLs in
  `style_sources/guides/manifest.json`. Network-only thin wrapper, kept out of unit tests.
- `GreenValidation.GuideAnalyzer` — given a source id, vendored markdown, and a curated
  `[{master_id, anchor}]` mapping, returns `{rules, unmapped}`: emits
  `{id, proposed: true, reference}` per mapped rule, flags anchors that don't resolve to a
  heading (drift), and lists uncovered headings as `unmapped`.
- `GreenValidation.CLI.AnalyzeGuide` — parameterised CLI: reads
  `style_sources/guides/<id>.md`, runs the analyzer, writes
  `style_sources/sources/<id>.json` via `SourceArtifact` (from 0004).

Lexmag-specific:
- `GreenValidation.Sources.Lexmag` — curated `[{master_id, anchor}]` mapping; every
  `master_id` must be a valid `StyleCatalog` id.
- `mix green_validation.analyze_lexmag` — thin task delegating to `AnalyzeGuide`.
</overview>

<tasks>
- [ ] Write `test/green_validation/guide_analyzer_test.exs`: against fixture markdown +
  mapping — emits mapped rules with references; missing anchor reported as drift;
  uncovered heading appears in `unmapped`. (red)
- [ ] Write `test/green_validation/sources/lexmag_test.exs`: the Lexmag mapping references
  only valid master ids. (red)
- [ ] Write `test/green_validation/cli/analyze_lexmag_test.exs`: given a vendored markdown
  file under `:tmp_dir`, the command writes a valid `lexmag.json` that parses. (red)
- [ ] Implement `GuideAnalyzer`. (green)
- [ ] Implement `CLI.AnalyzeGuide`. (green)
- [ ] Implement `Sources.Lexmag` + `Mix.Tasks.GreenValidation.AnalyzeLexmag`. (green)
- [ ] Implement the thin `fetch_style_guides` wrapper. (green)
- [ ] Run `fetch_style_guides` then `analyze_lexmag`; review the artifact + `unmapped`.
</tasks>

<principal_files>
- `lib/green_validation/cli/fetch_style_guides.ex` (new), `lib/mix/tasks/fetch_style_guides.ex` (new).
- `lib/green_validation/guide_analyzer.ex` (new), `lib/green_validation/cli/analyze_guide.ex` (new).
- `lib/green_validation/sources/lexmag.ex` (new), `lib/mix/tasks/analyze_lexmag.ex` (new).
- `style_sources/guides/lexmag.md` (+ `manifest.json`) and `style_sources/sources/lexmag.json` (outputs).
- Tests: `test/green_validation/guide_analyzer_test.exs`,
  `test/green_validation/sources/lexmag_test.exs`,
  `test/green_validation/cli/analyze_lexmag_test.exs`.
</principal_files>

<acceptance_criteria>
- [ ] `mix test` passes.
- [ ] `mix green_validation.fetch_style_guides` vendors three `.md` files + `manifest.json`.
- [ ] `mix green_validation.analyze_lexmag` writes a parseable `style_sources/sources/lexmag.json`.
- [ ] `proposed: true` entries carry an anchor that resolves into `guides/lexmag.md`.
- [ ] The Lexmag mapping references only valid `StyleCatalog` ids.
- [ ] `unmapped` lists guide sections not yet covered by the master list.
</acceptance_criteria>
