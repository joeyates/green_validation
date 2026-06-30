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
      assert by_id[:max_line_length].proposed
      assert by_id[:no_spaces_inside_brackets].proposed
      assert by_id[:no_semicolons].proposed
      assert by_id[:no_trailing_comma].proposed
      assert by_id[:omit_keyword_list_brackets].proposed
      assert by_id[:spaces_around_arrow].proposed
      assert by_id[:capture_operator_spacing].proposed
      assert by_id[:no_parens_around_anonymous_fn_args].proposed
      assert by_id[:lowercase_exponent].proposed
      assert by_id[:no_redundant_parentheses].proposed
      assert by_id[:no_spaces_in_bitstring_segments].proposed
      assert by_id[:fit_collections_on_one_line].proposed
      assert by_id[:comments_on_own_line].proposed
      assert by_id[:parens_on_definition_args].proposed
      assert by_id[:consistent_atom_quoting].proposed
      assert by_id[:space_before_zero_arity_arrow].proposed
      assert by_id[:spaces_around_default_arguments].proposed
      assert by_id[:no_expression_group_alignment].proposed
      assert by_id[:pipeline_indentation].proposed
      assert by_id[:no_space_after_unary_bang].proposed
      assert by_id[:no_blank_line_after_defmodule].proposed
      assert by_id[:omit_defstruct_brackets].proposed
      assert by_id[:binary_operator_at_line_end].proposed
      assert by_id[:multiline_collection_one_per_line].proposed
      assert by_id[:multiline_union_type].proposed
      assert by_id[:trailing_newline].proposed
    end

    test "classifies formatter-stable violations as not_enforced (not indeterminate)" do
      by_id = Map.new(MixFormat.analyze().rules, &{&1.id, &1})

      assert by_id[:verbose_map_syntax_for_mixed_keys].status == "not_enforced"
      assert by_id[:no_single_line_def_among_multiline].status == "not_enforced"
      assert by_id[:no_private_fn_same_name_as_public].status == "not_enforced"
    end

    test "marks formatter-ignored rules as not proposed" do
      by_id = Map.new(MixFormat.analyze().rules, &{&1.id, &1})

      refute by_id[:snake_case_atoms_and_variables].proposed
      refute by_id[:pipeline_for_chains].proposed
    end

    test "reports a status of enforced or not_enforced per rule" do
      by_id = Map.new(MixFormat.analyze().rules, &{&1.id, &1})

      assert by_id[:spaces_around_binary_operators].status == "enforced"
      assert by_id[:snake_case_atoms_and_variables].status == "not_enforced"
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
