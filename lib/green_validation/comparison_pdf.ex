defmodule GreenValidation.ComparisonPdf do
  @moduledoc """
  Renders a parsed `comparison.json` (the output of `mix green_validation.compare_styles`)
  into a printable PDF via PrawnEx — a pure-Elixir PDF library, no Chrome or HTML.

  The document opens with an introduction and a Sources list (each source with its
  reference URL). The rules are then split into blocks: first the rules `mix format`
  enforces (with a Category column, sorted by category then title), then one section per
  category for the rest. `mix format` is not a column — its enforcement is the grouping,
  and its parameter notes hang off the Rule column as numbered footnotes. Guide columns
  show `Yes` where the guide proposes the rule. An Examples section follows, each example's
  code on a grey panel. Pages are landscape A4 with a "Page N of M" footer.

  `PrawnEx.Layout` does not paginate, so each section's rows are chunked (`@rows_per_page`),
  a section heading is kept with its first chunk, and the header row repeats on each page.
  """

  alias PrawnEx.Document
  alias PrawnEx.Layout

  # Short, ASCII-only column headers (the standard Helvetica encoding has no ✓), keyed by
  # source id; falls back to the source's full name.
  @short_labels %{
    "mix_format" => "mix format",
    "lexmag" => "Lexmag",
    "credo" => "Credo",
    "christopher_adams" => "Adams"
  }

  @category_order [
    "formatting",
    "naming",
    "modules",
    "typespecs",
    "expressions",
    "documentation",
    "comments",
    "testing",
    "exceptions",
    "regex"
  ]

  @page_size {:a4, :landscape}
  @margins %{top: 60, left: 50, right: 50, bottom: 50}
  @source_col_width 70
  @row_height 22
  # Body rows per table chunk — small enough that a chunk (plus its repeated header, and
  # on the first page the intro) fits a landscape A4 page, so large sections paginate
  # instead of overflowing.
  @rows_per_page 14
  @category_column_width 90
  @enforced_title "Enforced by mix format"
  @heading_height 44
  @heading_space_before 16

  @doc """
  Builds the table rows: a header row (`"Rule"` plus a short label per source) followed
  by one row per master rule.
  """
  @spec rows(map()) :: [[String.t()]]
  def rows(comparison) do
    guides = guide_sources(comparison)
    numbers = comparison |> notes() |> number_map()

    [
      header_row(guides, false)
      | Enum.map(comparison["rules"], &body_row(&1, guides, numbers, false))
    ]
  end

  @doc """
  Splits the rules into display blocks: first `{"Enforced by mix format", rules}` for the
  rules `mix format` enforces, then one `{category_title, rules}` per category (in
  `@category_order`) for the rest. Empty blocks are omitted.
  """
  @spec sections(map()) :: [{String.t(), [map()]}]
  def sections(comparison) do
    {enforced, rest} = Enum.split_with(comparison["rules"], &mix_format_enforced?/1)

    enforced_section(enforced) ++ category_sections(rest)
  end

  # The examples list every rule grouped by category — unlike `sections/1`, the
  # mix-format-enforced rules are not pulled into a separate block.
  @spec example_sections(map()) :: [{String.t(), [map()]}]
  def example_sections(comparison), do: category_sections(comparison["rules"])

  defp sort_rules(rules), do: Enum.sort_by(rules, &String.downcase(&1["title"]))

  defp sort_by_category_then_title(rules) do
    Enum.sort_by(rules, &{&1["category"], String.downcase(&1["title"])})
  end

  @doc """
  Returns the parameter-level notes, numbered in table order. Each entry is a map with
  `:number`, `:rule_id`, `:source_id`, `:rule_title`, `:source_label` and `:note`.
  """
  @spec notes(map()) :: [map()]
  def notes(comparison) do
    sources = comparison["sources"]

    comparison
    |> sections()
    |> Enum.flat_map(fn {_title, rules} -> rules end)
    |> Enum.flat_map(fn rule ->
      for source <- sources,
          note = get_in(rule, ["sources", source["id"], "note"]),
          note != nil do
        %{
          rule_id: rule["id"],
          source_id: source["id"],
          rule_title: rule["title"],
          source_label: short_label(source),
          note: note
        }
      end
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {entry, number} -> Map.put(entry, :number, number) end)
  end

  defp number_map(notes), do: Map.new(notes, &{{&1.rule_id, &1.source_id}, &1.number})

  @doc """
  Renders the comparison to PDF bytes.

  Options:
    * `:version` — a version string (the git HEAD SHA) shown in the intro
    * `:generated_on` — the `Date` the PDF was generated, shown in the intro
  """
  @spec render(map(), keyword()) :: binary()
  def render(comparison, opts \\ []) do
    guides = guide_sources(comparison)
    sections = sections(comparison)
    notes = notes(comparison)
    numbers = number_map(notes)

    [page_size: @page_size]
    |> Document.new()
    |> PrawnEx.add_page()
    |> Layout.attach(page_size: @page_size, margins: @margins)
    |> heading("Elixir style: source comparison", 20, 16)
    |> Layout.paragraph(introduction(comparison, opts),
      font_size: 10,
      line_height: 15,
      gap_after: 14
    )
    |> Layout.paragraph(how_to_read(comparison), font_size: 9, line_height: 13, gap_after: 16)
    |> heading("Sources", 12, 14)
    |> Layout.paragraph(sources_block(comparison), font_size: 9, line_height: 14, gap_after: 20)
    |> render_matrix(sections, guides, numbers)
    |> render_notes(notes)
    |> render_examples(example_sections(comparison))
    |> Layout.to_doc()
    |> add_page_numbers()
    |> PrawnEx.to_binary()
  end

  defp add_page_numbers(doc) do
    total = length(doc.pages)

    doc.pages
    |> Enum.with_index()
    |> Enum.reduce(doc, fn {_page, index}, acc ->
      Document.inject_page_ops(acc, index, [], footer_ops(index + 1, total))
    end)
  end

  defp footer_ops(page_number, total) do
    Document.new()
    |> Document.add_page()
    |> PrawnEx.set_non_stroking_gray(0.5)
    |> PrawnEx.set_font("Helvetica", 8)
    |> PrawnEx.text_at({@margins.left, 28}, "Page #{page_number} of #{total}")
    |> Document.current_page()
    |> Map.fetch!(:content_ops)
  end

  # The "Enforced by mix format" block carries a Category column; the per-category blocks
  # don't (their heading is the category).
  defp render_matrix(layout, sections, guides, numbers) do
    Enum.reduce(sections, layout, fn {title, rules}, acc ->
      with_category = title == @enforced_title
      header = header_row(guides, with_category)
      column_widths = column_widths(guides, with_category)
      align = align(guides, with_category)

      chunks =
        rules
        |> Enum.map(&body_row(&1, guides, numbers, with_category))
        |> Enum.chunk_every(@rows_per_page)

      render_section(acc, title, header, chunks, column_widths, align)
    end)
  end

  defp render_section(layout, _title, _header, [], _column_widths, _align), do: layout

  defp render_section(layout, title, header, [first | rest], column_widths, align) do
    first_rows = [header | first]

    # Keep the section heading together with the first chunk (heading + repeated header
    # row + at least the first rows) so a heading never sits alone at the page foot.
    layout =
      layout
      |> ensure_room(@heading_height + section_height(first_rows))
      |> heading(title, 12, 4)
      |> table(first_rows, column_widths, align)

    Enum.reduce(rest, layout, fn chunk, acc ->
      table_rows = [header | chunk]

      acc
      |> ensure_room(section_height(table_rows))
      |> table(table_rows, column_widths, align)
    end)
  end

  defp render_notes(layout, []), do: layout

  defp render_notes(layout, notes) do
    layout = layout |> ensure_room(50) |> heading("Notes", 14, 8)

    Enum.reduce(notes, layout, fn note, acc ->
      text = "[#{note.number}] #{note.rule_title} (#{note.source_label}): #{note.note}"

      acc
      |> ensure_room(28)
      |> Layout.paragraph(text, font_size: 9, line_height: 13, gap_after: 13)
    end)
  end

  defp render_examples(layout, sections) do
    first_rule = sections |> List.first() |> elem(1) |> List.first()
    reserve = 60 + @heading_height + example_height(first_rule["example"])
    layout = layout |> ensure_room(reserve) |> heading("Examples", 18, 10)

    Enum.reduce(sections, layout, fn {title, rules}, acc ->
      render_example_section(acc, title, rules)
    end)
  end

  defp render_example_section(layout, _title, []), do: layout

  defp render_example_section(layout, title, [first | rest]) do
    # Keep the category sub-heading together with its first example block.
    layout =
      layout
      |> ensure_room(@heading_height + example_height(first["example"]))
      |> heading(title, 12, 4)
      |> example_block(first)

    Enum.reduce(rest, layout, fn rule, acc -> example_block(acc, rule) end)
  end

  @code_line_height 12

  defp example_block(layout, rule) do
    example = rule["example"]

    code_lines =
      String.split("# bad\n" <> example["bad"] <> "\n\n# good\n" <> example["good"], "\n")

    layout
    |> ensure_room(example_height(example))
    |> heading(rule["title"], 10, 12)
    |> render_code(code_lines)
  end

  # Renders code on a light-grey panel. Each line is drawn with `text_at` (not
  # `Layout.paragraph`, whose word wrapping drops leading whitespace), so indentation is
  # preserved.
  defp render_code(layout, lines) do
    Layout.escape(layout, fn doc, ctx ->
      pad = 5
      count = length(lines)
      first_baseline = ctx.cursor_y
      top = first_baseline + 9
      bottom = first_baseline - (count - 1) * @code_line_height - 4

      doc =
        doc
        |> PrawnEx.set_non_stroking_gray(0.95)
        |> PrawnEx.rectangle(
          ctx.content_left,
          bottom,
          ctx.content_width,
          top - bottom
        )
        |> PrawnEx.fill()
        |> PrawnEx.set_non_stroking_gray(0.0)
        |> PrawnEx.set_font("Courier", 9)

      doc =
        lines
        |> Enum.with_index()
        |> Enum.reduce(doc, fn {line, index}, acc ->
          baseline = first_baseline - index * @code_line_height
          PrawnEx.text_at(acc, {ctx.content_left + pad, baseline}, line)
        end)

      {doc, bottom - 14}
    end)
  end

  defp example_height(example) do
    # heading + the "# bad"/"# good" labels, a spacer line, the code lines, and padding
    lines = 3 + count_lines(example["bad"]) + count_lines(example["good"])
    40 + lines * @code_line_height
  end

  defp count_lines(text), do: text |> String.split("\n") |> length()

  defp enforced_section([]), do: []
  defp enforced_section(rules), do: [{@enforced_title, sort_by_category_then_title(rules)}]

  defp category_sections(rules) do
    by_category = Enum.group_by(rules, & &1["category"])
    extra = by_category |> Map.keys() |> Enum.reject(&(&1 in @category_order)) |> Enum.sort()

    (@category_order ++ extra)
    |> Enum.map(fn category ->
      {humanize(category), by_category |> Map.get(category, []) |> sort_rules()}
    end)
    |> Enum.reject(fn {_title, rules} -> rules == [] end)
  end

  defp mix_format_enforced?(rule), do: get_in(rule, ["sources", "mix_format", "proposed"]) == true

  defp humanize(category), do: String.capitalize(category)

  # The `mix format` source is not a column — its enforcement is conveyed by the
  # "Enforced by mix format" section, and its notes hang off the Rule column.
  defp guide_sources(comparison) do
    Enum.reject(comparison["sources"], &(&1["id"] == "mix_format"))
  end

  defp header_row(guides, with_category) do
    base = ["Rule" | Enum.map(guides, &short_label/1)]
    if with_category, do: ["Category" | base], else: base
  end

  defp body_row(rule, guides, numbers, with_category) do
    rule_cell = mark(rule["title"], Map.get(numbers, {rule["id"], "mix_format"}))
    base = [rule_cell | Enum.map(guides, fn source -> cell(rule, source["id"], numbers) end)]
    if with_category, do: [humanize(rule["category"]) | base], else: base
  end

  defp align(guides, with_category) do
    base = [:left | List.duplicate(:center, length(guides))]
    if with_category, do: [:left | base], else: base
  end

  defp mark(text, nil), do: text
  defp mark(text, number), do: "#{text} [#{number}]"

  # A heading with controlled spacing: a clear gap above (unless it sits at the top of a
  # page) so it never crowds the preceding content, and a tight gap below before the
  # following table/text. Drawn directly (not via Layout.heading, whose advance reserves a
  # whole line height below the baseline and pushes the table too far down).
  defp heading(layout, title, size, after_gap) do
    before = if at_page_top?(layout), do: 0, else: @heading_space_before

    Layout.escape(layout, fn doc, ctx ->
      baseline = ctx.cursor_y - before - size * 0.8

      doc =
        doc
        |> PrawnEx.set_non_stroking_gray(0.0)
        |> PrawnEx.set_font("Helvetica", size)
        |> PrawnEx.text_at({ctx.content_left, baseline}, title)

      {doc, baseline - size * 0.2 - after_gap}
    end)
  end

  defp at_page_top?(layout), do: layout.cursor_y >= layout.page_h - layout.margins.top - 1

  # Start a new page if `needed` points would overflow the bottom margin.
  defp ensure_room(layout, needed) do
    if layout.cursor_y - needed < layout.margins.bottom do
      layout.doc |> PrawnEx.add_page() |> Layout.attach(page_size: @page_size, margins: @margins)
    else
      layout
    end
  end

  # Heading + table clearance/after-gap (~48pt) plus one row height per row.
  defp section_height(table_rows), do: 48 + length(table_rows) * @row_height

  defp table(layout, rows, column_widths, align) do
    Layout.table(layout, rows,
      column_widths: column_widths,
      align: align,
      header: true,
      font_size: 9,
      header_font_size: 9,
      row_height: @row_height,
      clearance: 3
    )
  end

  # Guide cells read "Yes" where the guide proposes the rule, with a footnote marker when
  # there is a parameter-level note for that source.
  defp cell(rule, source_id, numbers) do
    base = if get_in(rule, ["sources", source_id, "proposed"]), do: "Yes", else: ""
    mark(base, Map.get(numbers, {rule["id"], source_id}))
  end

  defp short_label(source) do
    Map.get(@short_labels, source["id"], source["name"])
  end

  defp column_widths(guides, with_category) do
    {page_w, _} = PrawnEx.Units.page_size(@page_size)
    content_width = page_w - @margins.left - @margins.right
    source_total = @source_col_width * length(guides)

    if with_category do
      rule_width = content_width - @category_column_width - source_total
      [@category_column_width, rule_width | List.duplicate(@source_col_width, length(guides))]
    else
      rule_width = content_width - source_total
      [rule_width | List.duplicate(@source_col_width, length(guides))]
    end
  end

  defp introduction(comparison, opts) do
    rule_count = length(comparison["rules"])
    elixir_version = get_in(comparison, ["generated_with", "elixir_version"])

    "This comparison is produced by the green_validation project, a companion to green, the Elixir " <>
      "code formatter plugin. This document compares the four most widely used sources of " <>
      "truth for Elixir code style (the mix format formatter, Lexmag's style guide, Credo's " <>
      "style guide, and christopheradams' \"The Elixir Style Guide\") across #{rule_count} " <>
      "catalogued rules, showing which sources propose each one. Generated with Elixir " <>
      "#{elixir_version}." <> provenance(opts)
  end

  defp provenance(opts) do
    version = opts[:version]
    generated_on = opts[:generated_on]

    [
      version && "version #{version}",
      generated_on && "generated on #{Date.to_iso8601(generated_on)}"
    ]
    |> Enum.filter(& &1)
    |> case do
      [] -> ""
      parts -> " (" <> Enum.join(parts, ", ") <> ")."
    end
  end

  defp how_to_read(comparison) do
    no_source = comparison["rules_with_no_source"] || []

    base =
      "How to read it: each column is a style guide, and \"Yes\" marks where that guide " <>
        "proposes the rule. Rules are grouped first into those mix format enforces (shown with " <>
        "their category) and then by category. Numbered footnotes record parameter-level " <>
        "differences between sources, such as the maximum line length."

    case no_source do
      [] -> base
      ids -> base <> " Proposed by no source: #{Enum.join(ids, ", ")}."
    end
  end

  defp sources_block(comparison) do
    Enum.map_join(comparison["sources"], "\n", fn source ->
      "#{short_label(source)} = #{source["name"]}: #{source["repo_url"]}"
    end)
  end
end
