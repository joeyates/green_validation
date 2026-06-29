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
    {:no_else_in_unless, "no-unless-with-else"}
  ]

  @doc """
  Returns the `[{master_id, anchor}]` mapping for Credo's guide.
  """
  @spec mapping() :: [{atom(), String.t()}]
  def mapping(), do: @mapping
end
