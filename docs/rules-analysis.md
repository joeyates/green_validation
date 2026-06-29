# Style rule analysis

Alongside validating Green against real projects, this repository builds a **comparison
of the four recognised "sources of truth" for Elixir style**, showing which style rule
is proposed by which source:

1. **`mix format`** — the built-in formatter. Its rules are not documented as a list;
   they exist only as transformations in `Code.format_string!/2`.
2. **Lexmag's style guide** — <https://github.com/lexmag/elixir-style-guide>
3. **Credo's style guide** — <https://github.com/rrrene/elixir-style-guide>
4. **The Elixir Style Guide** (christopheradams) — <https://github.com/christopheradams/elixir_style_guide>

The analysis is a **pipeline of small mix tasks**, mirroring the
`github_repos`/`hexpm_packages` → `merge_sources` pattern: each source is analysed into
its own JSON artifact, and a final task joins them into a single comparison.

## The master rule list

Everything is anchored on a **master rule list** (`GreenValidation.StyleCatalog`): a
single, hand-curated list of named style rules. Each rule has a stable snake_case `id`
that is the cross-source key — `mix format` probes are keyed by it, each guide mapping
points at it, and the comparison has exactly one row per master rule.

The list is intentionally a starting point, not exhaustive. It is also the thing you
**edit to refine the output**: when an analyzer reports a rule it could not map (see
`unmapped` below), add an entry to the master list, teach the relevant analyzer about
it, and re-run the pipeline. Every task is deterministic, so re-running is always safe.

## Commands

Run them in this order (the analyzers are independent of each other; only `fetch` and
`compare` have ordering constraints):

```bash
# 0. (optional) dump the master rule list for review
mix green_validation.dump_master_rules        # -> style_sources/master_rules.json

# 1. vendor the three prose guides' markdown (network; run occasionally to refresh)
mix green_validation.fetch_style_guides        # -> style_sources/guides/*.md + manifest.json

# 2. analyse each source into its own artifact
mix green_validation.analyze_mix_format         # -> style_sources/sources/mix_format.json
mix green_validation.analyze_lexmag             # -> style_sources/sources/lexmag.json
mix green_validation.analyze_credo              # -> style_sources/sources/credo.json
mix green_validation.analyze_christopher_adams  # -> style_sources/sources/christopher_adams.json

# 3. join the per-source artifacts into the comparison
mix green_validation.compare_styles             # -> style_sources/comparison.json

# 4. (optional) render the comparison as a PDF
mix green_validation.comparison_pdf             # -> style_sources/comparison.pdf
```

Each command accepts `--output-path` (and the guide/compare commands accept
`--guides-path` / `--sources-path`) to override the defaults shown above.

### How `mix format`'s rules are discovered

`mix format` has no rule list, so `analyze_mix_format` determines membership
**empirically**. Each candidate rule has a probe — `%{input, expected}` — and the
analyzer formats `input` with `Code.format_string!/2`:

- formatted output equals `expected` → `status: "enforced"` — the formatter applies the
  rule (`proposed: true`);
- formatted output equals `input` → `status: "not_enforced"` — the formatter parses the
  code but leaves it alone (`proposed: false`);
- anything else → the probe is not isolated (it exercises more than one rule) and the
  task raises, so the probe can be split.

Unlike the guides, which *recommend* rules, `mix format` *enforces* them — hence the
distinct `status`, surfaced as `Enforced` in the PDF rather than `Yes`.

Probes for rules the formatter is expected to ignore (naming, pipelines, …) are included
on purpose — the negative results are what make the comparison meaningful. The analyzer
also runs a small corpus through the formatter and reports any transformation no probe
accounts for under `unmapped`.

### How the prose guides are analysed

The three guide analyzers read the **vendored** markdown (from `fetch_style_guides`) and
apply a curated `[{master_id, anchor}]` mapping, where `anchor` is the guide's per-rule
`<a name="...">` anchor. The shared `GuideAnalyzer`:

- emits `proposed: true` with a link to the anchor for each mapped rule;
- reports a mapping anchor that no longer resolves in the guide as **drift** (logged);
- lists the guide's rule anchors the mapping does not cover under `unmapped`.

## Output schemas

All files are written under `style_sources/`:

```
style_sources/
├── master_rules.json            # the master rule list (dump_master_rules)
├── guides/                       # vendored guide markdown (fetch_style_guides)
│   ├── lexmag.md
│   ├── credo.md
│   ├── christopher_adams.md
│   └── manifest.json
├── sources/                      # one per-source artifact per analyzer
│   ├── mix_format.json
│   ├── lexmag.json
│   ├── credo.json
│   └── christopher_adams.json
├── comparison.json               # the final comparison (compare_styles)
└── comparison.pdf                # printable matrix of the comparison (comparison_pdf)
```

### `comparison.pdf`

`mix green_validation.comparison_pdf` reads `comparison.json` and renders a printable
matrix — one row per master rule, one column per source — preceded by a legend mapping
the short column labels to the full source names. The cells distinguish the two kinds of
source: a guide column shows **`Yes`** where it proposes the rule, while the **`mix format`**
column shows **`Enforced`** where the formatter applies the rule automatically. It is built with
[PrawnEx](https://hex.pm/packages/prawn_ex), a pure-Elixir PDF library (no Chrome or
HTML), so it has no external runtime dependency.

### `master_rules.json`

A JSON array of master rules.

```json
[
  {
    "id": "spaces_around_binary_operators",
    "title": "Spaces around binary operators",
    "description": "Surround binary operators with a single space, e.g. `1 + 1`.",
    "category": "formatting"
  }
]
```

| Field | Type | Meaning |
|-------|------|---------|
| `id` | string | Stable, unique rule key used across all artifacts. |
| `title` | string | Short human-readable name. |
| `description` | string | One-line explanation. |
| `category` | string | One of `formatting`, `naming`, `modules`, `expressions`, `exceptions`. |

### `sources/<id>.json` (per-source artifact)

The output of one analyzer. `<id>` is one of `mix_format`, `lexmag`, `credo`,
`christopher_adams`.

```json
{
  "source": {
    "id": "mix_format",
    "name": "mix format",
    "repo_url": "https://github.com/elixir-lang/elixir"
  },
  "rules": [
    {
      "id": "spaces_around_binary_operators",
      "proposed": true,
      "status": "enforced",
      "reference": "code/formatter.ex — binary operator spacing"
    },
    {
      "id": "snake_case_atoms_and_variables",
      "proposed": false,
      "status": "not_enforced",
      "reference": "code.ex Code.format_string!/2 docs — does not hard code names"
    }
  ],
  "unmapped": [
    { "before": "foo( )", "after": "foo()" }
  ]
}
```

| Field | Type | Meaning |
|-------|------|---------|
| `source.id` / `name` / `repo_url` | string | Identifies the source. |
| `rules[].id` | string | A master rule id. |
| `rules[].proposed` | boolean | Whether this source proposes/enforces the rule. |
| `rules[].status` | string | **`mix_format` only.** `"enforced"` or `"not_enforced"` (see above). Absent for the prose guides, which recommend rather than enforce. |
| `rules[].reference` | string | Where in the source the rule is found — an Elixir source location for `mix_format`, or a URL into the guide anchor for the guides. |
| `unmapped` | array | Things the analyzer found but could not map to a master rule. For `mix_format` these are `{before, after}` formatter transformations; for guides they are `{anchor}` rule anchors. These drive the refinement loop. |

### `comparison.json` (the deliverable)

`compare_styles` reads the four per-source artifacts and joins them over the master list.
A source whose artifact is missing is treated as absent, so the comparison still builds
from a partial pipeline.

```json
{
  "generated_with": {
    "elixir_version": "1.19.5"
  },
  "sources": [
    { "id": "mix_format", "name": "mix format", "repo_url": "https://github.com/elixir-lang/elixir" },
    { "id": "lexmag", "name": "Lexmag's Elixir Style Guide", "repo_url": "https://github.com/lexmag/elixir-style-guide" },
    { "id": "credo", "name": "Credo's Elixir Style Guide", "repo_url": "https://github.com/rrrene/elixir-style-guide" },
    { "id": "christopher_adams", "name": "The Elixir Style Guide", "repo_url": "https://github.com/christopheradams/elixir_style_guide" }
  ],
  "rules": [
    {
      "id": "spaces_around_binary_operators",
      "title": "Spaces around binary operators",
      "category": "formatting",
      "proposed_by": ["mix_format", "lexmag", "credo", "christopher_adams"],
      "sources": {
        "mix_format":        { "proposed": true,  "status": "enforced", "reference": "code/formatter.ex — binary operator spacing" },
        "lexmag":            { "proposed": true,  "reference": "https://github.com/lexmag/elixir-style-guide#spaces-in-code" },
        "credo":             { "proposed": true,  "reference": "https://github.com/rrrene/elixir-style-guide#spaces-operators" },
        "christopher_adams": { "proposed": true,  "reference": "https://github.com/christopheradams/elixir_style_guide#spaces" }
      }
    }
  ],
  "rules_with_no_source": ["alphabetical_alias_order"]
}
```

| Field | Type | Meaning |
|-------|------|---------|
| `generated_with` | object | The Elixir version the comparison was built with (the `mix format` column is produced by probing that formatter). |
| `sources` | array | The four sources being compared (id, name, repo URL). |
| `rules` | array | One entry per master rule. |
| `rules[].id` / `title` / `category` | string | Copied from the master rule. |
| `rules[].proposed_by` | array | The source ids that propose the rule (in source order). |
| `rules[].sources` | object | Per-source verdict, keyed by source id. Each value has `proposed` (boolean) and, when known, a `reference`; the `mix_format` entry also carries `status` (`enforced`/`not_enforced`). |
| `rules_with_no_source` | array | Master rule ids that no source proposes — possible spurious or mis-named entries to revisit. This closes the refinement loop in the opposite direction to each analyzer's `unmapped`. |

## Refinement loop

1. **Run** the pipeline and review `comparison.json`.
2. **Notice gaps** — each analyzer's `unmapped` lists guide rules / formatter behaviours
   not yet in the master list, and `compare_styles` reports `rules_with_no_source`.
3. **Refine** — add the rule to `GreenValidation.StyleCatalog`, then add a probe
   (`Sources.MixFormat`) and/or an anchor to the relevant guide mapping
   (`Sources.Lexmag` / `Sources.Credo` / `Sources.ChristopherAdams`).
4. **Re-run** — the output improves. Repeat.
