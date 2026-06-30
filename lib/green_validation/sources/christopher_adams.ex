defmodule GreenValidation.Sources.ChristopherAdams do
  @moduledoc """
  Curated mapping from master rule ids to anchors in The Elixir Style Guide
  (christopheradams).

  Anchors are the guide's per-rule `<a name="...">` anchors. The guide's many rules with
  no master equivalent (keyword-list syntax, map key shorthand, typedocs, annotations,
  metaprogramming, …) surface via the analyzer's `unmapped` report.
  """

  @mapping [
    {:no_trailing_whitespace, "trailing-whitespace"},
    {:trailing_newline, "newline-eof"},
    {:unix_line_endings, "line-endings"},
    {:max_line_length, "line-length"},
    {:spaces_around_binary_operators, "spaces"},
    {:spaces_after_commas, "spaces"},
    {:no_spaces_inside_brackets, "spaces"},
    {:no_spaces_around_range_operator, "no-spaces"},
    {:no_space_after_unary_bang, "no-spaces"},
    {:comment_leading_space, "comment-leading-spaces"},
    {:pipeline_for_chains, "pipe-operator"},
    {:no_pipeline_for_single_call, "avoid-single-pipelines"},
    {:no_else_in_unless, "unless-with-else"},
    {:true_as_last_cond_clause, "true-as-last-condition"},
    {:parentheses_on_zero_arity_calls, "parentheses-and-functions-with-zero-arity"},
    {:snake_case_atoms_and_variables, "snake-case"},
    {:camel_case_modules, "camel-case"},
    {:predicate_function_question_mark, "predicate-function-trailing-question-mark"},
    {:module_pseudo_variable, "module-pseudo-variable"},
    {:module_attribute_layout, "module-attribute-ordering"},
    {:exception_error_suffix, "exception-names"},
    {:lowercase_exception_messages, "lowercase-error-messages"},
    {:no_trailing_punctuation_in_exception_messages, "lowercase-error-messages"},
    {:omit_keyword_list_brackets, "keyword-list-brackets"},
    {:comments_on_own_line, "comments-above-line"},
    {:alphabetical_alias_order, "module-attribute-ordering"},
    # Enrichment of rules added from other guides.
    {:assertion_argument_order, "testing-assert-order"},
    {:concatenation_when_matching_binaries, "strings-matching-with-concatenator"},
    {:snake_case_files, "underscored-filenames"},
    {:with_clause_indentation, "with-clauses"},
    {:no_explicit_nil_struct_defaults, "nil-struct-field-defaults"},
    {:moduledoc_false_when_undocumented, "moduledoc-false"},
    {:blank_line_after_moduledoc, "moduledoc-spacing"},
    {:parens_in_function_calls, "function-calls-and-parentheses"},
    {:group_function_clauses, "single-line-defs"},
    {:pipe_chains_start_with_raw_value, "bare-variables"},
    {:vertical_space_for_readability, "def-spacing"},
    # New rules.
    {:blank_line_after_multiline_assignment, "add-blank-line-after-multiline-assignment"},
    {:alias_self_reference, "alias-self-referencing-modules"},
    {:avoid_metaprogramming, "avoid-metaprogramming"},
    {:comment_grammar, "comment-grammar"},
    {:comment_line_length, "comment-line-length"},
    {:no_blank_line_after_defmodule, "defmodule-spacing"},
    {:do_colon_for_single_line_if, "do-with-single-line-if-unless"},
    {:omit_parens_on_zero_arg_defs, "fun-def-parentheses"},
    {:no_space_before_call_parens, "function-names-with-parentheses"},
    {:heredocs_for_documentation, "heredocs"},
    {:keyword_list_special_syntax, "keyword-list-syntax"},
    {:long_do_clause_on_new_line, "long-dos"},
    {:verbose_map_syntax_for_mixed_keys, "map-key-arrow"},
    {:shorthand_map_syntax_for_atom_keys, "map-key-atom"},
    {:module_name_matches_path, "module-name-nesting"},
    {:always_moduledoc, "moduledocs"},
    {:multiline_case_clause_blank_lines, "multiline-case-clauses"},
    {:multiline_collection_one_per_line, "multiline-enums"},
    {:multiline_collection_one_per_line, "multiline-structs"},
    {:multiline_assign_bracket_placement, "multiline-list-assign"},
    {:no_single_line_def_among_multiline, "multiple-function-defs"},
    {:main_type_named_t, "naming-main-types"},
    {:one_module_per_file, "one-module-per-file"},
    {:parens_on_piped_calls, "parentheses-pipe-operator"},
    {:predicate_guard_is_prefix, "predicate-function-is-prefix"},
    {:no_private_fn_same_name_as_public, "private-functions-with-same-name-as-public"},
    {:no_repetitive_module_names, "repetitive-module-names"},
    {:spec_directly_before_function, "spec-spacing"},
    {:omit_defstruct_brackets, "struct-def-brackets"},
    {:group_typedoc_with_type, "typedocs"},
    {:multiline_union_type, "union-types"},
    {:with_else_formatting, "with-else"},
    {:annotation_keywords, "annotations"},
    {:annotation_keywords, "annotation-keyword"},
    {:annotation_keywords, "todo-notes"},
    {:annotation_keywords, "fixme-notes"},
    {:annotation_keywords, "optimize-notes"},
    {:annotation_keywords, "hack-notes"},
    {:annotation_keywords, "review-notes"},
    {:annotation_keywords, "custom-keywords"},
    {:annotation_keywords, "exceptions-to-annotations"}
  ]

  @doc """
  Returns the `[{master_id, anchor}]` mapping for The Elixir Style Guide.
  """
  @spec mapping() :: [{atom(), String.t()}]
  def mapping(), do: @mapping
end
