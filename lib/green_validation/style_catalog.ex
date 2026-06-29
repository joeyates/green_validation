defmodule GreenValidation.StyleCatalog do
  @moduledoc """
  The master rule list: a single, hand-curated global list of named Elixir style
  rules.

  This is the stable naming system the rest of the comparison refers to. Every rule
  `id` is a snake_case atom that is the cross-source key — `mix format` probes are
  keyed by it, each guide analysis maps its prose to it, and the final comparison has
  one row per master rule. Ids are stable: renaming one is a deliberate breaking change
  (every analyzer that references it must update), so prefer adding over renaming.

  Each rule is a map with `:id`, `:title`, `:description` and `:category`. The list is
  intentionally a starting point, not exhaustive — the comparison pipeline reports what
  it could not map (see the analyzers' `unmapped` output), and rules are added here as
  they are discovered.
  """

  @type category :: :formatting | :naming | :modules | :expressions | :exceptions

  @type t :: %{
          id: atom(),
          title: String.t(),
          description: String.t(),
          category: category()
        }

  @rules [
    # Formatting — mostly `mix format` territory.
    %{
      id: :spaces_around_binary_operators,
      title: "Spaces around binary operators",
      description: "Surround binary operators with a single space, e.g. `1 + 1`.",
      category: :formatting
    },
    %{
      id: :no_spaces_around_range_operator,
      title: "No spaces around the range operator",
      description: "Write ranges without surrounding spaces, e.g. `1..2`.",
      category: :formatting
    },
    %{
      id: :two_space_indentation,
      title: "Two-space indentation",
      description: "Indent with two spaces per level; never use tabs.",
      category: :formatting
    },
    %{
      id: :max_line_length,
      title: "Maximum line length",
      description: "Keep lines within a maximum length (98 columns for `mix format`).",
      category: :formatting
    },
    %{
      id: :no_trailing_whitespace,
      title: "No trailing whitespace",
      description: "Strip whitespace from the end of lines.",
      category: :formatting
    },
    %{
      id: :spaces_after_commas,
      title: "Space after commas",
      description: "Put a single space after each comma and none before it.",
      category: :formatting
    },
    %{
      id: :no_spaces_inside_brackets,
      title: "No spaces inside brackets",
      description:
        "Do not pad the inside of (), [] or {} with spaces, e.g. `[1, 2]` not `[ 1, 2 ]`.",
      category: :formatting
    },
    %{
      id: :no_semicolons,
      title: "No semicolons between statements",
      description: "Write each statement on its own line; do not use `;` to separate statements.",
      category: :formatting
    },
    %{
      id: :no_trailing_comma,
      title: "No trailing comma in collections",
      description:
        "Do not leave a trailing comma after the last element of a list, map, tuple or call.",
      category: :formatting
    },
    %{
      id: :collapse_consecutive_blank_lines,
      title: "Collapse consecutive blank lines",
      description: "Squeeze multiple blank lines into a single blank line.",
      category: :formatting
    },
    %{
      id: :comment_leading_space,
      title: "Space after the comment marker",
      description: "Write comments as `# comment`, with one space after the `#`.",
      category: :formatting
    },
    %{
      id: :digit_grouping_underscores,
      title: "Group digits in large numbers",
      description:
        "Use underscores to group digits in numbers over five digits, e.g. `1_000_000`.",
      category: :formatting
    },
    %{
      id: :uppercase_hex_literals,
      title: "Uppercase hexadecimal literals",
      description: "Write hexadecimal digits in uppercase, e.g. `0xABCD`.",
      category: :formatting
    },
    %{
      id: :unix_line_endings,
      title: "Unix line endings",
      description: "Use `\\n` line endings; convert `\\r\\n` to `\\n`.",
      category: :formatting
    },
    %{
      id: :trailing_newline,
      title: "Trailing newline at end of file",
      description: "End every file with a single trailing newline.",
      category: :formatting
    },

    # Naming.
    %{
      id: :snake_case_atoms_and_variables,
      title: "snake_case for atoms, variables and functions",
      description: "Name atoms, variables and functions in snake_case.",
      category: :naming
    },
    %{
      id: :camel_case_modules,
      title: "CamelCase for modules",
      description: "Name modules in CamelCase (PascalCase).",
      category: :naming
    },
    %{
      id: :predicate_function_question_mark,
      title: "Question mark for predicate functions",
      description: "Name boolean-returning functions with a trailing `?` and no `is_` prefix.",
      category: :naming
    },
    %{
      id: :avoid_one_letter_variables,
      title: "Avoid one-letter variable names",
      description: "Prefer descriptive names over single letters.",
      category: :naming
    },

    # Modules.
    %{
      id: :alphabetical_alias_order,
      title: "Order alias/import/require alphabetically",
      description: "Sort module references (alias, import, require, use) alphabetically.",
      category: :modules
    },
    %{
      id: :module_pseudo_variable,
      title: "Use the __MODULE__ pseudo-variable",
      description: "Refer to the current module with `__MODULE__` rather than its full name.",
      category: :modules
    },
    %{
      id: :module_attribute_layout,
      title: "Consistent module attribute layout",
      description:
        "Order module-level forms consistently: @moduledoc, use, import, alias, require, then attributes.",
      category: :modules
    },

    # Expressions.
    %{
      id: :pipeline_for_chains,
      title: "Use pipelines for chained calls",
      description: "Use the pipe operator for chains of function calls.",
      category: :expressions
    },
    %{
      id: :no_pipeline_for_single_call,
      title: "Avoid needless pipelines",
      description: "Do not use a pipeline for a single function call.",
      category: :expressions
    },
    %{
      id: :no_anonymous_functions_in_pipelines,
      title: "No anonymous functions in pipelines",
      description: "Do not invoke anonymous functions directly inside a pipeline.",
      category: :expressions
    },
    %{
      id: :no_else_in_unless,
      title: "No else clause with unless",
      description: "Never use `unless` with an `else` branch; rewrite as `if`.",
      category: :expressions
    },
    %{
      id: :true_as_last_cond_clause,
      title: "Use true as the last cond clause",
      description: "Use `true` (not `:else` or similar) for the catch-all `cond` clause.",
      category: :expressions
    },
    %{
      id: :parentheses_on_zero_arity_calls,
      title: "Parentheses on zero-arity function calls",
      description: "Call zero-arity functions with parentheses, e.g. `foo()`.",
      category: :expressions
    },
    %{
      id: :omit_keyword_list_brackets,
      title: "Omit brackets from keyword lists",
      description:
        "Omit the square brackets around a keyword list when they are optional, e.g. `foo(a: 1)`.",
      category: :expressions
    },
    %{
      id: :spaces_around_arrow,
      title: "Spaces around the -> operator",
      description:
        "Surround the `->` operator with spaces, e.g. `fn x -> x end` and case clauses.",
      category: :formatting
    },
    %{
      id: :capture_operator_spacing,
      title: "Capture operator spacing",
      description:
        "Write the capture operator with a space and without wrapping parentheses, e.g. `& &1`.",
      category: :formatting
    },
    %{
      id: :no_parens_around_anonymous_fn_args,
      title: "No parentheses around anonymous function arguments",
      description: "Write `fn x -> … end`, not `fn(x) -> … end`.",
      category: :expressions
    },
    %{
      id: :no_redundant_parentheses,
      title: "No redundant parentheses",
      description: "Drop parentheses that only group an expression, e.g. `1 + 2` not `(1 + 2)`.",
      category: :expressions
    },
    %{
      id: :lowercase_exponent,
      title: "Lowercase exponent letter in floats",
      description: "Write the exponent letter in lowercase, e.g. `1.0e3` not `1.0E3`.",
      category: :formatting
    },
    %{
      id: :no_spaces_in_bitstring_segments,
      title: "No spaces around bitstring segment options",
      description: "Do not put spaces around `::` in bitstring segments, e.g. `<<1::8>>`.",
      category: :formatting
    },
    %{
      id: :fit_collections_on_one_line,
      title: "Fit collections on a single line when they fit",
      description:
        "Collapse a list, map, tuple or call onto one line when it fits within the line length.",
      category: :formatting
    },
    %{
      id: :comments_on_own_line,
      title: "Comments on their own line",
      description:
        "Place a comment on the line above the code it refers to, not trailing after it.",
      category: :formatting
    },

    # Exceptions.
    %{
      id: :exception_error_suffix,
      title: "Error suffix for exception modules",
      description: "Name exception modules with an `Error` suffix.",
      category: :exceptions
    },
    %{
      id: :lowercase_exception_messages,
      title: "Lowercase exception messages",
      description: "Begin exception messages with a lowercase letter.",
      category: :exceptions
    },
    %{
      id: :no_trailing_punctuation_in_exception_messages,
      title: "No trailing punctuation in exception messages",
      description: "Do not end exception messages with punctuation.",
      category: :exceptions
    }
  ]

  @doc """
  Returns the master rule list.
  """
  @spec all() :: [t()]
  def all(), do: @rules

  @ids Enum.map(@rules, & &1.id)

  @doc """
  Returns every master rule id, in list order.
  """
  @spec ids() :: [atom()]
  def ids(), do: @ids

  @doc """
  Returns `true` if `id` is a known master rule id.
  """
  @spec valid_id?(atom()) :: boolean()
  def valid_id?(id), do: id in @ids
end
