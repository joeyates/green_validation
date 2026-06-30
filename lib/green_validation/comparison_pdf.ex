defmodule GreenValidation.ComparisonPdf do
  @moduledoc """
  Renders a parsed `comparison.json` (the output of `mix green_validation.compare_styles`)
  into a printable PDF via PrawnEx — a pure-Elixir PDF library, no Chrome or HTML.

  The rules are split into blocks: first the rules `mix format` enforces, then one section
  per category for the rest. Each block is a heading plus a matrix (one row per rule, one
  column per source) with `Enforced`/`Yes` cells. A legend maps the short column labels to
  the full source names. `PrawnEx.Layout` does not paginate, so a new page is started
  between blocks when one would not fit (each block is assumed to fit on a page).
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

  @page_size :a4
  @margins %{top: 60, left: 50, right: 50, bottom: 50}
  @source_col_width 70
  @row_height 22

  @doc """
  Builds the table rows: a header row (`"Rule"` plus a short label per source) followed
  by one row per master rule.
  """
  @spec rows(map()) :: [[String.t()]]
  def rows(comparison) do
    sources = comparison["sources"]
    [header_row(comparison) | Enum.map(comparison["rules"], &body_row(&1, sources))]
  end

  @doc """
  Splits the rules into display blocks: first `{"Enforced by mix format", rules}` for the
  rules `mix format` enforces, then one `{category_title, rules}` per category (in
  `@category_order`) for the rest. Empty blocks are omitted.
  """
  @spec sections(map()) :: [{String.t(), [map()]}]
  def sections(comparison) do
    {enforced, rest} = Enum.split_with(comparison["rules"], &mix_format_enforced?/1)

    (enforced |> sort_rules() |> enforced_section()) ++ category_sections(rest)
  end

  defp sort_rules(rules), do: Enum.sort_by(rules, &String.downcase(&1["title"]))

  @doc """
  Renders the comparison to PDF bytes.
  """
  @spec render(map()) :: binary()
  def render(comparison) do
    header = header_row(comparison)
    column_widths = column_widths(comparison["sources"])
    align = [:left | List.duplicate(:center, length(comparison["sources"]))]

    sources = comparison["sources"]
    sections = sections(comparison)

    Document.new()
    |> PrawnEx.add_page()
    |> Layout.attach(page_size: @page_size, margins: @margins)
    |> Layout.heading("Elixir style: source comparison", font_size: 18)
    |> Layout.paragraph(intro(comparison), font_size: 9, gap_after: 6)
    |> Layout.paragraph(legend(comparison), font_size: 9, gap_after: 10)
    |> render_matrix(sections, header, column_widths, align, sources)
    |> render_examples(sections)
    |> Layout.to_doc()
    |> PrawnEx.to_binary()
  end

  defp render_matrix(layout, sections, header, column_widths, align, sources) do
    Enum.reduce(sections, layout, fn {title, rules}, acc ->
      table_rows = [header | Enum.map(rules, &body_row(&1, sources))]

      acc
      |> ensure_room(section_height(table_rows))
      |> Layout.heading(title, font_size: 12, gap_after: 4)
      |> table(table_rows, column_widths, align)
    end)
  end

  defp render_examples(layout, sections) do
    layout = layout |> ensure_room(40) |> Layout.heading("Examples", font_size: 18, gap_after: 8)

    Enum.reduce(sections, layout, fn {title, rules}, acc ->
      acc = acc |> ensure_room(40) |> Layout.heading(title, font_size: 12, gap_after: 4)
      Enum.reduce(rules, acc, fn rule, inner -> example_block(inner, rule) end)
    end)
  end

  defp example_block(layout, rule) do
    example = rule["example"]
    code = "# bad\n" <> example["bad"] <> "\n\n# good\n" <> example["good"]

    layout
    |> ensure_room(example_height(example))
    |> Layout.heading(rule["title"], font_size: 10, gap_after: 3)
    |> Layout.paragraph(code, font_name: "Courier", font_size: 9, line_height: 12, gap_after: 14)
  end

  defp example_height(example) do
    # heading + the "# bad"/"# good" labels, a spacer line, and the code lines
    lines = 3 + count_lines(example["bad"]) + count_lines(example["good"])
    30 + lines * 12
  end

  defp count_lines(text), do: text |> String.split("\n") |> length()

  defp enforced_section([]), do: []
  defp enforced_section(rules), do: [{"Enforced by mix format", rules}]

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

  defp header_row(comparison) do
    ["Rule" | Enum.map(comparison["sources"], &short_label/1)]
  end

  defp body_row(rule, sources) do
    [rule["title"] | Enum.map(sources, fn source -> cell(rule, source["id"]) end)]
  end

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
      row_height: @row_height
    )
  end

  # A source that carries a `status` (mix format) enforces rather than recommends, so its
  # cell reads "Enforced"; the prose guides recommend, so theirs reads "Yes".
  defp cell(rule, source_id) do
    entry = get_in(rule, ["sources", source_id]) || %{}

    cond do
      Map.has_key?(entry, "status") -> status_label(entry["status"])
      entry["proposed"] -> "Yes"
      true -> ""
    end
  end

  defp status_label("enforced"), do: "Enforced"
  defp status_label(_), do: ""

  defp short_label(source) do
    Map.get(@short_labels, source["id"], source["name"])
  end

  defp column_widths(sources) do
    {page_w, _} = PrawnEx.Units.page_size(@page_size)
    content_width = page_w - @margins.left - @margins.right
    rule_width = content_width - @source_col_width * length(sources)
    [rule_width | List.duplicate(@source_col_width, length(sources))]
  end

  defp intro(comparison) do
    version = get_in(comparison, ["generated_with", "elixir_version"])
    rule_count = length(comparison["rules"])
    no_source = comparison["rules_with_no_source"] || []

    base =
      "Generated with Elixir #{version}. A guide column shows \"Yes\" where it proposes " <>
        "the rule; the mix format column shows \"Enforced\" where the formatter applies it " <>
        "automatically. #{rule_count} master rules."

    case no_source do
      [] -> base
      ids -> base <> " Proposed by no source: #{Enum.join(ids, ", ")}."
    end
  end

  defp legend(comparison) do
    entries =
      Enum.map_join(comparison["sources"], "; ", fn source ->
        "#{short_label(source)} = #{source["name"]}"
      end)

    "Sources — #{entries}."
  end
end
