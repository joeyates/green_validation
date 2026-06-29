defmodule GreenValidation.Sources.MixFormatTest do
  use ExUnit.Case, async: true

  alias GreenValidation.Sources.MixFormat
  alias GreenValidation.StyleCatalog

  describe "analyze/0" do
    test "marks formatter-enforced rules as proposed" do
      by_id = Map.new(MixFormat.analyze().rules, &{&1.id, &1})

      assert by_id[:spaces_around_binary_operators].proposed
      assert by_id[:no_spaces_around_range_operator].proposed
      assert by_id[:digit_grouping_underscores].proposed
      assert by_id[:no_spaces_inside_brackets].proposed
      assert by_id[:no_semicolons].proposed
    end

    test "marks formatter-ignored rules as not proposed" do
      by_id = Map.new(MixFormat.analyze().rules, &{&1.id, &1})

      refute by_id[:snake_case_atoms_and_variables].proposed
      refute by_id[:pipeline_for_chains].proposed
    end

    test "every emitted rule id is a valid master id" do
      for rule <- MixFormat.analyze().rules do
        assert StyleCatalog.valid_id?(rule.id)
      end
    end

    test "every proposed rule carries a reference" do
      for rule <- MixFormat.analyze().rules, rule.proposed do
        assert is_binary(rule.reference) and rule.reference != ""
      end
    end

    test "reports formatter transformations no probe accounts for as unmapped" do
      assert MixFormat.analyze().unmapped != []
    end
  end

  describe "probes/0" do
    test "every probe's expected form is idempotent under the formatter" do
      for probe <- MixFormat.probes() do
        formatted = probe.expected |> Code.format_string!() |> IO.iodata_to_binary()

        assert formatted == String.trim_trailing(probe.expected, "\n"),
               "probe #{probe.id} has a non-idempotent expected form"
      end
    end

    test "every probe targets a valid master id" do
      for probe <- MixFormat.probes() do
        assert StyleCatalog.valid_id?(probe.id)
      end
    end
  end
end
