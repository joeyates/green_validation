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
    {:alphabetical_alias_order, "module-attribute-ordering"}
  ]

  @doc """
  Returns the `[{master_id, anchor}]` mapping for The Elixir Style Guide.
  """
  @spec mapping() :: [{atom(), String.t()}]
  def mapping(), do: @mapping
end
