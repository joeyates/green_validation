defmodule GreenValidation.Rules do
  @moduledoc """
  Green's rules.
  """

  @doc """
  Returns a list of all Green rules.

  These keys correspond to the snake_case names used in .formatter.exs configuration for Green.
  """
  @spec all() :: list(atom())
  def all() do
    [
      :avoid_needless_pipelines,
      :no_anonymous_functions_in_pipelines,
      :no_unless_with_else,
      :no_nil_else,
      :true_in_cond,
      :boolean_operators,
      :use_string_concatenation_when_matching_binaries,
      :avoid_one_letter_variables,
      :predicate_functions,
      :upper_camel_case_for_modules,
      :sort_module_references,
      :use_module_pseudo_variable,
      :remove_nil_from_struct_definition,
      :use_error_suffix,
      :lowercase_exception_messages,
      :no_trailing_punctuation_in_exception_messages,
      :prefer_pipelines,
      :avoid_caps,
      :use_parentheses_with_zero_arity_functions
    ]
  end
end
