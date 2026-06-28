<title>mix format analysis command</title>

<description>
`mix format`'s rules are undocumented as a list — they exist only as transformations in
`Code.format_string!/2`. This command determines which master rules (from plan 0003) the
formatter enforces, **empirically**, and writes them as a per-source artifact that plan
0008 merges into the comparison.

Feasibility experiment (done during planning): `mix format`'s rules are *partially*
recoverable from Elixir's own source (Elixir 1.19.5 at
`~/.asdf/installs/elixir/1.19.5/lib/elixir/lib/`) — (1) the `@doc` for
`Code.format_string!/2` in `code.ex` (≈ lines 714–1090) describes many behaviours in
prose, and (2) `code/formatter.ex` has declarative attribute tables
(`@no_space_binary_operators`, `@locals_without_parens`, `@pipeline_operators`, …). But
the bulk of formatting is emergent from the `Inspect.Algebra` fit-or-break layout, so
source gives good candidate *names* while proof requires running the formatter.

So: candidates are harvested from source + the master list; each is verified with a
probe. A probe is `{input: <violates rule>, expected: <satisfies rule>}`, and
`MixFormatProbe.enforced?/1` asks whether `Code.format_string!/2` turns `input` into
`expected`. Attribution is enforced mechanically: `input` must be otherwise idempotent
(differ from `expected` only in the feature under test), `expected` must satisfy
`format(expected) == expected`, and any third-form output raises so non-isolated probes
are caught and split. Validated live: enforced — operator spacing (`1+1`→`1 + 1`), range
spacing (`1 .. 2`→`1..2`), digit grouping (`1000000`→`1_000_000`), hex case
(`0xabcd`→`0xABCD`), blank-line squeezing, CRLF→LF; not enforced (unchanged) — pipe-start
style, `:fooBar` casing, sigil delimiter, `do:` shorthand. The run also caught a
non-isolated probe: `"x = 1 #comment"` → `"# comment\nx = 1"` (leading-space AND comment
hoisting) — must be split into two probes.
</description>

<branch>0004_mix_format_analysis</branch>

<overview>
- `GreenValidation.MixFormatProbe.enforced?/1` — `%{input, expected}` → enforced /
  not-enforced / raise (non-isolated).
- `GreenValidation.Sources.MixFormat.analyze/0` — runs the probe table (master id →
  probe + Elixir source reference) and returns the rule list plus `unmapped` (corpus
  transformations no probe accounts for, feeding the refinement loop).
- `GreenValidation.SourceArtifact` — shared helper to write a per-source artifact as
  pretty JSON (reused by 0005–0007): `{ "source": {…}, "rules": [{id, proposed,
  reference}], "unmapped": […] }`.
- `mix green_validation.analyze_mix_format` — thin Mix task → CLI module (pattern of
  `merge_sources`) writing `style_sources/sources/mix_format.json` (switch `--output-path`).
Probe coverage includes master rules expected to be ignored — the negative results are
what make the comparison meaningful.
</overview>

<tasks>
- [ ] Write `test/green_validation/mix_format_probe_test.exs`: positive
  (`"1+1\n"`→`"1 + 1\n"`), negative (already-formatted unchanged), malformed/third-form
  raises. (red)
- [ ] Write `test/green_validation/sources/mix_format_test.exs`: `analyze/0` reflects
  probe results (never hand-set); every probe `expected` is idempotent under
  `Code.format_string!/2`; every emitted id is a valid master id. (red)
- [ ] Write `test/green_validation/cli/analyze_mix_format_test.exs`: writes valid JSON
  under `:tmp_dir`; artifact parses, has the `mix_format` source block and a `rules`
  list. (red)
- [ ] Implement `MixFormatProbe`. (green)
- [ ] Implement `Sources.MixFormat` with the probe table + gap sweep. (green)
- [ ] Implement `SourceArtifact` writer. (green)
- [ ] Implement `CLI.AnalyzeMixFormat` + Mix task. (green)
- [ ] Run `mix green_validation.analyze_mix_format` and review the artifact + `unmapped`.
</tasks>

<principal_files>
- `lib/green_validation/mix_format_probe.ex` (new).
- `lib/green_validation/sources/mix_format.ex` (new) — probe table + `analyze/0`.
- `lib/green_validation/source_artifact.ex` (new) — shared artifact writer.
- `lib/green_validation/cli/analyze_mix_format.ex` (new), `lib/mix/tasks/analyze_mix_format.ex` (new).
- `style_sources/sources/mix_format.json` (output).
- Tests: `test/green_validation/mix_format_probe_test.exs`,
  `test/green_validation/sources/mix_format_test.exs`,
  `test/green_validation/cli/analyze_mix_format_test.exs`.
- References (read-only): `~/.asdf/installs/elixir/1.19.5/lib/elixir/lib/code.ex`,
  `.../lib/code/formatter.ex`.
</principal_files>

<acceptance_criteria>
- [ ] `mix test` passes.
- [ ] `mix green_validation.analyze_mix_format` writes a parseable
  `style_sources/sources/mix_format.json`.
- [ ] Spacing/indentation rules show `proposed: true`; naming/pipe-style rules `false`.
- [ ] Every emitted rule id is a valid `StyleCatalog` id; every probe `expected` is
  idempotent under the formatter.
- [ ] `unmapped` lists any formatter transformations not yet covered by a master rule.
</acceptance_criteria>
