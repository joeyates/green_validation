defmodule GreenValidation.Sources.Credo do
  @moduledoc """
  Curated mapping from master rule ids to anchors in Credo's Elixir Style Guide.

  Anchors are the guide's per-rule `<a name="...">` anchors. Credo rules with no master
  equivalent (sigils, regexes, documentation, FIXME/TODO, nested conditionals, …) are
  left out and surface via the analyzer's `unmapped` report for later folding into the
  master list.
  """

  @mapping [
    {:two_space_indentation, "spaces-indentation"},
    {:unix_line_endings, "line-endings"},
    {:no_trailing_whitespace, "no-trailing-whitespace"},
    {:trailing_newline, "newline-eof"},
    {:spaces_around_binary_operators, "spaces-operators"},
    {:spaces_after_commas, "spaces-operators"},
    {:no_spaces_inside_brackets, "spaces-braces"},
    {:max_line_length, "character-per-line-limit"},
    {:digit_grouping_underscores, "underscores-in-numerics"},
    {:camel_case_modules, "camelcase-modules"},
    {:snake_case_atoms_and_variables, "snake-case-attributes-functions-macros-vars"},
    {:exception_error_suffix, "exception-naming"},
    {:predicate_function_question_mark, "predicates"},
    {:module_pseudo_variable, "reference-current-module"},
    {:no_else_in_unless, "no-unless-with-else"},
    {:no_semicolons, "semicolon-between-statements"},
    # Enrichment of rules added from other guides.
    {:regex_string_anchors, "caret-and-dollar-regex"},
    {:parens_on_definition_args, "function-parens"},
    {:multiline_expression_assignment, "multi-line-call"},
    # New rules.
    {:alias_all_used_modules, "alias-modules"},
    {:no_negated_unless, "avoid-double-negations"},
    {:no_parens_around_conditionals, "conditional-parens"},
    {:no_constant_conditionals, "debugging-conditionals"},
    {:prefer_docs_over_comments, "doc-comments"},
    {:moduledoc_false_when_undocumented, "doc-false"},
    {:blank_line_after_moduledoc, "doc-style"},
    {:annotation_keywords, "fixme"},
    {:annotation_keywords, "todo"},
    {:parens_in_function_calls, "function-calling-parens"},
    {:group_function_clauses, "group-function-definitions"},
    {:no_iex_pry_in_production, "iex-pry"},
    {:no_io_inspect_in_production, "io-inspect"},
    {:no_shadowing_kernel_names, "kernel-functions"},
    {:no_shadowing_stdlib_modules, "stdlib-modules"},
    {:no_nested_conditionals, "no-nested-conditionals"},
    {:no_space_after_unary_bang, "no-space-bang"},
    {:pipe_chains_start_with_raw_value, "pipe-chains"},
    {:prefer_regex_sigil, "regex-sigils"},
    {:vertical_space_for_readability, "vertical-space"}
  ]

  @doc """
  Returns the `[{master_id, anchor}]` mapping for Credo's guide.
  """
  @spec mapping() :: [{atom(), String.t()}]
  def mapping(), do: @mapping
end
