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
          optional(:reference) => String.t() | nil
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

  defp row(rule, source_ids, source_rules) do
    sources =
      Map.new(source_ids, fn source_id ->
        {source_id, source_rules |> find(source_id, rule.id) |> source_entry()}
      end)

    proposed_by = Enum.filter(source_ids, &sources[&1].proposed)

    %{
      id: rule.id,
      title: rule.title,
      category: rule.category,
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
    case entry[:reference] do
      nil -> %{proposed: proposed}
      reference -> %{proposed: proposed, reference: reference}
    end
  end

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
