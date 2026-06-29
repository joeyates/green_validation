defmodule GreenValidation.ComparisonPdf do
  @moduledoc """
  Renders a parsed `comparison.json` (the output of `mix green_validation.compare_styles`)
  into a printable PDF via PrawnEx — a pure-Elixir PDF library, no Chrome or HTML.

  The PDF is a matrix: one row per master rule, one column per source, with `Yes` where
  the source proposes the rule. A legend maps the short column labels to the full source
  names. `PrawnEx.Layout` does not paginate, so rows are chunked across A4 pages here.
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

  @page_size :a4
  @margins %{top: 60, left: 50, right: 50, bottom: 50}
  @source_col_width 70
  @row_height 22
  # Conservative row counts that fit an A4 page (less on page 1, which carries the intro).
  @first_page_rows 22
  @page_rows 28

  @doc """
  Builds the table rows: a header row (`"Rule"` plus a short label per source) followed
  by one row per master rule, with `"Yes"` where the source proposes it and `""` otherwise.
  """
  @spec rows(map()) :: [[String.t()]]
  def rows(comparison) do
    sources = comparison["sources"]
    header = ["Rule" | Enum.map(sources, &short_label/1)]

    body =
      Enum.map(comparison["rules"], fn rule ->
        cells = Enum.map(sources, fn source -> cell(rule, source["id"]) end)
        [rule["title"] | cells]
      end)

    [header | body]
  end

  @doc """
  Renders the comparison to PDF bytes.
  """
  @spec render(map()) :: binary()
  def render(comparison) do
    [header | body] = rows(comparison)
    column_widths = column_widths(comparison["sources"])
    align = [:left | List.duplicate(:center, length(comparison["sources"]))]
    [first_chunk | rest_chunks] = paginate(body)

    Document.new()
    |> first_page(comparison, header, first_chunk, column_widths, align)
    |> more_pages(header, rest_chunks, column_widths, align)
    |> PrawnEx.to_binary()
  end

  defp first_page(doc, comparison, header, chunk, column_widths, align) do
    doc
    |> PrawnEx.add_page()
    |> Layout.attach(page_size: @page_size, margins: @margins)
    |> Layout.heading("Elixir style: source comparison", font_size: 18)
    |> Layout.paragraph(intro(comparison), font_size: 9, gap_after: 6)
    |> Layout.paragraph(legend(comparison), font_size: 9, gap_after: 10)
    |> table([header | chunk], column_widths, align)
    |> Layout.to_doc()
  end

  defp more_pages(doc, header, chunks, column_widths, align) do
    Enum.reduce(chunks, doc, fn chunk, acc ->
      acc
      |> PrawnEx.add_page()
      |> Layout.attach(page_size: @page_size, margins: @margins)
      |> table([header | chunk], column_widths, align)
      |> Layout.to_doc()
    end)
  end

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

  defp paginate(body) do
    case Enum.split(body, @first_page_rows) do
      {first, []} -> [first]
      {first, rest} -> [first | Enum.chunk_every(rest, @page_rows)]
    end
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
