defmodule GreenValidation.Sources.Lexmag do
  @moduledoc """
  Curated mapping from master rule ids to anchors in Lexmag's Elixir Style Guide.

  Anchors are the guide's per-rule `<a name="...">` anchors. Master rules that Lexmag
  does not address are simply absent; the analyzer reports the guide's unmapped rule
  anchors so they can be folded into the master list over time.
  """

  @mapping [
    {:pipeline_for_chains, "pipeline-operator"},
    {:no_pipeline_for_single_call, "needless-pipeline"},
    {:no_anonymous_functions_in_pipelines, "anonymous-pipeline"},
    {:no_else_in_unless, "no-else-with-unless"},
    {:true_as_last_cond_clause, "true-in-cond"},
    {:snake_case_atoms_and_variables, "snake-case-atoms-funs-vars-attrs"},
    {:camel_case_modules, "camelcase-modules"},
    {:predicate_function_question_mark, "predicate-funs-name"},
    {:avoid_one_letter_variables, "one-letter-var"},
    {:comment_leading_space, "leading-space-comment"},
    {:module_attribute_layout, "module-layout"},
    {:module_pseudo_variable, "current-module-reference"},
    {:exception_error_suffix, "exception-naming"},
    {:lowercase_exception_messages, "exception-message"},
    {:no_trailing_punctuation_in_exception_messages, "exception-message"},
    {:no_trailing_whitespace, "no-trailing-whitespaces"},
    {:trailing_newline, "newline-eof"},
    {:two_space_indentation, "spaces-indentation"},
    {:spaces_around_binary_operators, "spaces-in-code"},
    {:spaces_after_commas, "spaces-in-code"},
    {:no_spaces_around_range_operator, "no-spaces-in-code"},
    {:no_space_after_unary_bang, "no-spaces-in-code"},
    {:digit_grouping_underscores, "underscores-in-numerics"},
    {:uppercase_hex_literals, "hex-literals"},
    {:parentheses_on_zero_arity_calls, "zero-arity-parens"},
    {:no_semicolons, "no-semicolon"},
    {:no_trailing_comma, "trailing-comma"},
    {:no_parens_around_anonymous_fn_args, "anonymous-fun-parens"},
    {:no_spaces_in_bitstring_segments, "bitstring-segment-options"},
    {:boolean_operators, "boolean-operators"},
    {:no_nil_else, "no-nil-else"},
    {:concatenation_when_matching_binaries, "patterns-matching-binaries"},
    {:parens_on_definition_args, "fun-parens"},
    {:snake_case_files, "snake-case-dirs-files"},
    {:no_explicit_nil_struct_defaults, "defstruct-fields-default"},
    {:parens_on_zero_arity_types, "parens-in-zero-arity-types"},
    {:consistent_atom_quoting, "quotes-around-atoms"},
    {:space_before_zero_arity_arrow, "space-before-anonymous-fun-arrow"},
    {:spaces_around_default_arguments, "default-arguments"},
    {:no_expression_group_alignment, "expression-group-alignment"},
    {:pipeline_indentation, "pipeline-indentation"},
    {:binary_operator_at_line_end, "binary-operators-at-eols"},
    {:multiline_binary_operand_indentation, "binary-ops-indentation"},
    {:guard_clause_indentation, "guard-clauses"},
    {:multiline_expression_assignment, "multi-line-expr-assignment"},
    {:with_clause_indentation, "with-indentation"},
    {:for_clause_indentation, "for-indentation"},
    {:comments_for_important_details, "critical-comments"},
    {:no_superfluous_comments, "no-superfluous-comments"},
    {:assertion_argument_order, "exunit-assertion-side"},
    {:prefer_pattern_matching_over_regex, "pattern-matching-over-regexp"},
    {:non_capturing_regex_groups, "non-capturing-regexp"},
    {:regex_string_anchors, "caret-and-dollar-regexp"}
  ]

  @doc """
  Returns the `[{master_id, anchor}]` mapping for Lexmag's guide.
  """
  @spec mapping() :: [{atom(), String.t()}]
  def mapping(), do: @mapping
end
