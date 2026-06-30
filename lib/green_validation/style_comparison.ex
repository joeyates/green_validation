defmodule GreenValidation.StyleComparison do
  @moduledoc """
  Joins the per-source rule artifacts into a single comparison, one row per master rule.

  `build/1` takes `%{source_id => [%{id: master_id, proposed: boolean, reference:
  string}]}` — decoupled from the filesystem so it is easy to test — and returns a plain
  data structure ready to encode as JSON. The shared master `id` is the grouping key:
  every master rule becomes one row, and each source's verdict is looked up by id. A
  source with no artifact (absent from the input) is reported as not proposing any rule.
  """

  alias GreenValidation.StyleCatalog
  alias GreenValidation.StyleSource

  @type source_rule :: %{
          required(:id) => atom(),
          required(:proposed) => boolean(),
          optional(:reference) => String.t() | nil,
          optional(:status) => String.t() | nil
        }

  @spec build(%{atom() => [source_rule()]}) :: map()
  def build(source_rules) do
    validate_ids!(source_rules)

    source_ids = Enum.map(StyleSource.all(), & &1.id)
    rules = Enum.map(StyleCatalog.all(), &row(&1, source_ids, source_rules))

    %{
      generated_with: %{elixir_version: System.version()},
      sources: Enum.map(StyleSource.all(), &%{id: &1.id, name: &1.name, repo_url: &1.repo_url}),
      rules: rules,
      rules_with_no_source: rules |> Enum.filter(&(&1.proposed_by == [])) |> Enum.map(& &1.id)
    }
  end

  # Curated parameter-level notes, keyed by `{rule_id, source_id}`. These annotate rules
  # the sources agree on but parameterise differently (so the boolean matrix can't show
  # the disagreement), surfaced as numbered footnotes in the PDF.
  @notes %{
    {:max_line_length, :mix_format} => "98-column default",
    {:max_line_length, :credo} => "keep lines under 80 characters",
    {:max_line_length, :christopher_adams} => "limit lines to 98 characters",
    {:module_attribute_layout, :lexmag} => "order: use, import, alias, require",
    {:module_attribute_layout, :christopher_adams} => "order: use, import, require, alias"
  }

  defp row(rule, source_ids, source_rules) do
    sources =
      Map.new(source_ids, fn source_id ->
        entry =
          source_rules
          |> find(source_id, rule.id)
          |> source_entry()
          |> maybe_put(:note, Map.get(@notes, {rule.id, source_id}))

        {source_id, entry}
      end)

    proposed_by = Enum.filter(source_ids, &sources[&1].proposed)

    %{
      id: rule.id,
      title: rule.title,
      category: rule.category,
      example: rule.example,
      proposed_by: proposed_by,
      sources: sources
    }
  end

  defp find(source_rules, source_id, rule_id) do
    source_rules
    |> Map.get(source_id, [])
    |> Enum.find(&(&1.id == rule_id))
  end

  defp source_entry(nil), do: %{proposed: false}

  defp source_entry(%{proposed: proposed} = entry) do
    %{proposed: proposed}
    |> maybe_put(:reference, entry[:reference])
    |> maybe_put(:status, entry[:status])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp validate_ids!(source_rules) do
    unknown =
      for {_source_id, rules} <- source_rules,
          rule <- rules,
          not StyleCatalog.valid_id?(rule.id),
          do: rule.id

    case Enum.uniq(unknown) do
      [] -> :ok
      ids -> raise ArgumentError, "unknown master rule id(s): #{inspect(ids)}"
    end
  end
end
