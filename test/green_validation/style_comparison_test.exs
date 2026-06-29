defmodule GreenValidation.StyleComparisonTest do
  use ExUnit.Case, async: true

  alias GreenValidation.StyleCatalog
  alias GreenValidation.StyleComparison

  @source_rules %{
    mix_format: [
      %{id: :spaces_around_binary_operators, proposed: true, reference: "formatter.ex"},
      %{id: :snake_case_atoms_and_variables, proposed: false, reference: "docs"}
    ],
    lexmag: [
      %{id: :snake_case_atoms_and_variables, proposed: true, reference: "https://lexmag#snake"}
    ]
  }

  describe "build/1" do
    test "has one row per master rule" do
      result = StyleComparison.build(@source_rules)

      assert length(result.rules) == length(StyleCatalog.all())
    end

    test "lists the four sources" do
      result = StyleComparison.build(@source_rules)
      ids = result.sources |> Enum.map(& &1.id) |> Enum.sort()

      assert ids == [:christopher_adams, :credo, :lexmag, :mix_format]
    end

    test "proposed_by reflects which sources propose each rule" do
      result = StyleComparison.build(@source_rules)
      by_id = Map.new(result.rules, &{&1.id, &1})

      assert by_id[:spaces_around_binary_operators].proposed_by == [:mix_format]
      assert by_id[:snake_case_atoms_and_variables].proposed_by == [:lexmag]
    end

    test "reports a source whose rule is not listed as not proposed" do
      result = StyleComparison.build(@source_rules)
      by_id = Map.new(result.rules, &{&1.id, &1})

      refute by_id[:spaces_around_binary_operators].sources.credo.proposed
    end

    test "flags master rules that no source proposes" do
      result = StyleComparison.build(@source_rules)

      assert :two_space_indentation in result.rules_with_no_source
    end

    test "carries a mix format status through to the source entry" do
      source_rules = %{
        mix_format: [
          %{
            id: :spaces_around_binary_operators,
            proposed: true,
            reference: "f",
            status: "enforced"
          }
        ]
      }

      result = StyleComparison.build(source_rules)
      row = Enum.find(result.rules, &(&1.id == :spaces_around_binary_operators))

      assert row.sources.mix_format.status == "enforced"
    end

    test "includes each rule's bad/good example" do
      result = StyleComparison.build(@source_rules)
      row = Enum.find(result.rules, &(&1.id == :spaces_around_binary_operators))

      assert row.example.bad == "1+1"
      assert row.example.good == "1 + 1"
    end

    test "rejects an unknown rule id" do
      assert_raise ArgumentError, fn ->
        StyleComparison.build(%{mix_format: [%{id: :not_a_real_master_rule, proposed: true}]})
      end
    end
  end
end
