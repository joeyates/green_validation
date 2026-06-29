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
    {:digit_grouping_underscores, "underscores-in-numerics"},
    {:uppercase_hex_literals, "hex-literals"},
    {:parentheses_on_zero_arity_calls, "zero-arity-parens"},
    {:no_semicolons, "no-semicolon"},
    {:no_trailing_comma, "trailing-comma"}
  ]

  @doc """
  Returns the `[{master_id, anchor}]` mapping for Lexmag's guide.
  """
  @spec mapping() :: [{atom(), String.t()}]
  def mapping(), do: @mapping
end
