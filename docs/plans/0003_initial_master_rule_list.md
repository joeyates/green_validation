<title>Generate an initial master rule list</title>

<description>
The goal of plans 0003–0008 is a JSON comparison of the four "sources of truth" for
Elixir style — `mix format`, Lexmag's guide, Credo's guide, and christopheradams' guide
— showing which style rule is proposed by which source.

The centre of that design is a **master rule list**: a single, hand-curated global list
of named style rules. It is the stable naming system everything refers to — `mix format`
probes are keyed by master rule id (0004), each guide analysis maps prose to master rule
ids (0005–0007), and the final comparison has one row per master rule (0008). The master
list is also what you **edit to refine**: notice a missing rule, add one entry, re-run
the pipeline, get better output.

This plan delivers that list (seeded, not exhaustive — the refinement loop grows it
later) plus the registry of the four sources, and a command to dump the list to JSON for
review.

The initial list is seeded by harvesting candidates and consolidating synonyms into
single named rules: (1) from `mix format`'s own source — every `formatter.ex` attribute
table and every behaviour documented in the `Code.format_string!/2` `@doc`; (2) from each
prose guide's table of contents. Deduplicate across sources by meaning (e.g. all four
notions of max line length → one `:max_line_length`). Target ~20–30 rules across the main
categories.
</description>

<branch>0003_initial_master_rule_list</branch>

<overview>
Introduce two foundational vocabularies as Elixir modules:
- `GreenValidation.StyleCatalog` — the master rule list (`id`, `title`, `description`,
  `category`), with `ids/0` and `valid_id?/1` for downstream validation. Ids are stable,
  unique, snake_case; renaming is a deliberate breaking change, prefer adding.
- `GreenValidation.StyleSource` — registry of the four sources (`id`, `name`, `repo_url`,
  `raw_url`, `branch`), with `all/0` and `prose/0`.
Plus a `mix green_validation.dump_master_rules` command that writes the list to
`style_sources/master_rules.json` so it can be reviewed and diffed as it grows. Follows
the thin-Mix-task → CLI-module pattern of `lib/mix/tasks/merge_sources.ex` +
`lib/green_validation/cli/merge_sources.ex`.
</overview>

<tasks>
- [ ] Write `test/green_validation/style_catalog_test.exs`: non-empty; unique ids; every
  entry has title/category; `valid_id?/1` and `ids/0` behave. (red)
- [ ] Write `test/green_validation/style_source_test.exs`: the four sources present with
  required metadata; `prose/0` returns the three fetchable guides. (red)
- [ ] Write `test/green_validation/cli/dump_master_rules_test.exs`: command writes valid
  JSON under an ExUnit `:tmp_dir` (use `@describetag :tmp_dir`, as `project_test.exs`);
  file parses and lists every master rule. (red)
- [ ] Implement `GreenValidation.StyleCatalog`, seeded with ~20–30 master rules. (green)
- [ ] Implement `GreenValidation.StyleSource`. (green)
- [ ] Implement `GreenValidation.CLI.DumpMasterRules` + `Mix.Tasks.GreenValidation.DumpMasterRules`. (green)
- [ ] Run `mix green_validation.dump_master_rules` and review `master_rules.json`.
</tasks>

<principal_files>
- `lib/green_validation/style_catalog.ex` (new) — master rule list.
- `lib/green_validation/style_source.ex` (new) — source registry.
- `lib/green_validation/cli/dump_master_rules.ex` (new), `lib/mix/tasks/dump_master_rules.ex` (new).
- `style_sources/master_rules.json` (output, generated).
- Tests: `test/green_validation/style_catalog_test.exs`, `test/green_validation/style_source_test.exs`,
  `test/green_validation/cli/dump_master_rules_test.exs`.
</principal_files>

<acceptance_criteria>
- [ ] `mix test` passes.
- [ ] `StyleCatalog` lists ~20–30 master rules with unique, stable snake_case ids and
  title/description/category each.
- [ ] `StyleSource` exposes the four sources; `prose/0` returns three.
- [ ] `mix green_validation.dump_master_rules` writes a parseable
  `style_sources/master_rules.json` listing every master rule.
- [ ] No dependency on later plans.
</acceptance_criteria>
