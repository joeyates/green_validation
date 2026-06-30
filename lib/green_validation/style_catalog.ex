defmodule GreenValidation.StyleCatalog do
  @moduledoc """
  The master rule list: a single, hand-curated global list of named Elixir style
  rules.

  This is the stable naming system the rest of the comparison refers to. Every rule
  `id` is a snake_case atom that is the cross-source key — `mix format` probes are
  keyed by it, each guide analysis maps its prose to it, and the final comparison has
  one row per master rule. Ids are stable: renaming one is a deliberate breaking change
  (every analyzer that references it must update), so prefer adding over renaming.

  Each rule is a map with `:id`, `:title`, `:description`, `:category` and an `:example`
  (`%{bad: ..., good: ...}`). The list is intentionally a starting point, not exhaustive —
  the comparison pipeline reports what it could not map (see the analyzers' `unmapped`
  output), and rules are added here as they are discovered.
  """

  @type category ::
          :formatting
          | :naming
          | :modules
          | :expressions
          | :exceptions
          | :typespecs
          | :documentation
          | :comments
          | :testing
          | :regex

  @type t :: %{
          id: atom(),
          title: String.t(),
          description: String.t(),
          category: category(),
          example: %{bad: String.t(), good: String.t()}
        }

  @rules [
    # Formatting — mostly `mix format` territory.
    %{
      id: :spaces_around_binary_operators,
      title: "Spaces around binary operators",
      description: "Surround binary operators with a single space, e.g. `1 + 1`.",
      category: :formatting,
      example: %{bad: "1+1", good: "1 + 1"}
    },
    %{
      id: :no_spaces_around_range_operator,
      title: "No spaces around the range operator",
      description: "Write ranges without surrounding spaces, e.g. `1..2`.",
      category: :formatting,
      example: %{bad: "1 .. 2", good: "1..2"}
    },
    %{
      id: :two_space_indentation,
      title: "Two-space indentation",
      description: "Indent with two spaces per level; never use tabs.",
      category: :formatting,
      example: %{bad: "if x do\n    :ok\nend", good: "if x do\n  :ok\nend"}
    },
    %{
      id: :max_line_length,
      title: "Maximum line length",
      description: "Keep lines within a maximum length (98 columns for `mix format`).",
      category: :formatting,
      example: %{
        bad:
          "result = some_function(argument_one, argument_two, argument_three, argument_four, argument_five, argument_six)",
        good:
          "result =\n  some_function(\n    argument_one,\n    argument_two,\n    argument_three,\n    argument_four,\n    argument_five,\n    argument_six\n  )"
      }
    },
    %{
      id: :no_trailing_whitespace,
      title: "No trailing whitespace",
      description: "Strip whitespace from the end of lines.",
      category: :formatting,
      example: %{bad: "x = 1   ", good: "x = 1"}
    },
    %{
      id: :spaces_after_commas,
      title: "Space after commas",
      description: "Put a single space after each comma and none before it.",
      category: :formatting,
      example: %{bad: "[1,2]", good: "[1, 2]"}
    },
    %{
      id: :no_spaces_inside_brackets,
      title: "No spaces inside brackets",
      description:
        "Do not pad the inside of (), [] or {} with spaces, e.g. `[1, 2]` not `[ 1, 2 ]`.",
      category: :formatting,
      example: %{bad: "[ 1, 2 ]", good: "[1, 2]"}
    },
    %{
      id: :no_semicolons,
      title: "No semicolons between statements",
      description: "Write each statement on its own line; do not use `;` to separate statements.",
      category: :formatting,
      example: %{bad: "a = 1; b = 2", good: "a = 1\nb = 2"}
    },
    %{
      id: :no_trailing_comma,
      title: "No trailing comma in collections",
      description:
        "Do not leave a trailing comma after the last element of a list, map, tuple or call.",
      category: :formatting,
      example: %{bad: "[1, 2,]", good: "[1, 2]"}
    },
    %{
      id: :collapse_consecutive_blank_lines,
      title: "Collapse consecutive blank lines",
      description: "Squeeze multiple blank lines into a single blank line.",
      category: :formatting,
      example: %{bad: "a = 1\n\n\nb = 2", good: "a = 1\n\nb = 2"}
    },
    %{
      id: :comment_leading_space,
      title: "Space after the comment marker",
      description: "Write comments as `# comment`, with one space after the `#`.",
      category: :formatting,
      example: %{bad: "#comment", good: "# comment"}
    },
    %{
      id: :digit_grouping_underscores,
      title: "Group digits in large numbers",
      description:
        "Use underscores to group digits in numbers over five digits, e.g. `1_000_000`.",
      category: :formatting,
      example: %{bad: "1000000", good: "1_000_000"}
    },
    %{
      id: :uppercase_hex_literals,
      title: "Uppercase hexadecimal literals",
      description: "Write hexadecimal digits in uppercase, e.g. `0xABCD`.",
      category: :formatting,
      example: %{bad: "0xabcd", good: "0xABCD"}
    },
    %{
      id: :unix_line_endings,
      title: "Unix line endings",
      description: "Use `\\n` line endings; convert `\\r\\n` to `\\n`.",
      category: :formatting,
      example: %{bad: "a = 1\\r\\nb = 2", good: "a = 1\\nb = 2"}
    },
    %{
      id: :trailing_newline,
      title: "Trailing newline at end of file",
      description: "End every file with a single trailing newline.",
      category: :formatting,
      example: %{bad: "(file ends without a newline)", good: "(file ends with one \\n)"}
    },

    # Naming.
    %{
      id: :snake_case_atoms_and_variables,
      title: "snake_case for atoms, variables and functions",
      description: "Name atoms, variables and functions in snake_case.",
      category: :naming,
      example: %{bad: "fooBar = 1", good: "foo_bar = 1"}
    },
    %{
      id: :camel_case_modules,
      title: "CamelCase for modules",
      description: "Name modules in CamelCase (PascalCase).",
      category: :naming,
      example: %{bad: "defmodule My_app do\nend", good: "defmodule MyApp do\nend"}
    },
    %{
      id: :predicate_function_question_mark,
      title: "Question mark for predicate functions",
      description: "Name boolean-returning functions with a trailing `?` and no `is_` prefix.",
      category: :naming,
      example: %{bad: "def is_valid(x), do: true", good: "def valid?(x), do: true"}
    },
    %{
      id: :avoid_one_letter_variables,
      title: "Avoid one-letter variable names",
      description: "Prefer descriptive names over single letters.",
      category: :naming,
      example: %{bad: "u = get_user()", good: "user = get_user()"}
    },

    # Modules.
    %{
      id: :alphabetical_alias_order,
      title: "Order alias/import/require alphabetically",
      description: "Sort module references (alias, import, require, use) alphabetically.",
      category: :modules,
      example: %{
        bad: "alias App.Zebra\nalias App.Apple",
        good: "alias App.Apple\nalias App.Zebra"
      }
    },
    %{
      id: :module_pseudo_variable,
      title: "Use the __MODULE__ pseudo-variable",
      description: "Refer to the current module with `__MODULE__` rather than its full name.",
      category: :modules,
      example: %{bad: "%MyApp.User{name: n}", good: "%__MODULE__{name: n}"}
    },
    %{
      id: :module_attribute_layout,
      title: "Consistent module attribute layout",
      description:
        "Order module-level directives (@moduledoc, use, import, require, alias, attributes, …) " <>
          "in a consistent, defined sequence. The exact sequence differs between guides — see " <>
          "each source's reference (e.g. Lexmag orders alias before require, christopheradams the reverse).",
      category: :modules,
      example: %{
        bad: "alias App.X\nuse GenServer\n@moduledoc \"...\"",
        good: "@moduledoc \"...\"\nuse GenServer\nalias App.X"
      }
    },

    # Expressions.
    %{
      id: :pipeline_for_chains,
      title: "Use pipelines for chained calls",
      description: "Use the pipe operator for chains of function calls.",
      category: :expressions,
      example: %{bad: "f(g(h(x)))", good: "x |> h() |> g() |> f()"}
    },
    %{
      id: :no_pipeline_for_single_call,
      title: "Avoid needless pipelines",
      description: "Do not use a pipeline for a single function call.",
      category: :expressions,
      example: %{bad: "x |> f()", good: "f(x)"}
    },
    %{
      id: :no_anonymous_functions_in_pipelines,
      title: "No anonymous functions in pipelines",
      description: "Do not invoke anonymous functions directly inside a pipeline.",
      category: :expressions,
      example: %{bad: "x |> (fn v -> v + 1 end).()", good: "x |> increment()"}
    },
    %{
      id: :no_else_in_unless,
      title: "No else clause with unless",
      description: "Never use `unless` with an `else` branch; rewrite as `if`.",
      category: :expressions,
      example: %{bad: "unless x do\n  a\nelse\n  b\nend", good: "if x do\n  b\nelse\n  a\nend"}
    },
    %{
      id: :true_as_last_cond_clause,
      title: "Use true as the last cond clause",
      description: "Use `true` (not `:else` or similar) for the catch-all `cond` clause.",
      category: :expressions,
      example: %{
        bad: "cond do\n  x -> 1\n  :else -> 2\nend",
        good: "cond do\n  x -> 1\n  true -> 2\nend"
      }
    },
    %{
      id: :parentheses_on_zero_arity_calls,
      title: "Parentheses on zero-arity function calls",
      description: "Call zero-arity functions with parentheses, e.g. `foo()`.",
      category: :expressions,
      example: %{bad: "DateTime.utc_now", good: "DateTime.utc_now()"}
    },
    %{
      id: :omit_keyword_list_brackets,
      title: "Omit brackets from keyword lists",
      description:
        "Omit the square brackets around a keyword list when they are optional, e.g. `foo(a: 1)`.",
      category: :expressions,
      example: %{bad: "foo([a: 1])", good: "foo(a: 1)"}
    },
    %{
      id: :spaces_around_arrow,
      title: "Spaces around the -> operator",
      description:
        "Surround the `->` operator with spaces, e.g. `fn x -> x end` and case clauses.",
      category: :formatting,
      example: %{bad: "fn x->x end", good: "fn x -> x end"}
    },
    %{
      id: :capture_operator_spacing,
      title: "Capture operator spacing",
      description:
        "Write the capture operator with a space and without wrapping parentheses, e.g. `& &1`.",
      category: :formatting,
      example: %{bad: "&(&1)", good: "& &1"}
    },
    %{
      id: :no_parens_around_anonymous_fn_args,
      title: "No parentheses around anonymous function arguments",
      description: "Write `fn x -> … end`, not `fn(x) -> … end`.",
      category: :expressions,
      example: %{bad: "fn(x) -> x end", good: "fn x -> x end"}
    },
    %{
      id: :no_redundant_parentheses,
      title: "No redundant parentheses",
      description: "Drop parentheses that only group an expression, e.g. `1 + 2` not `(1 + 2)`.",
      category: :expressions,
      example: %{bad: "(1 + 2)", good: "1 + 2"}
    },
    %{
      id: :lowercase_exponent,
      title: "Lowercase exponent letter in floats",
      description: "Write the exponent letter in lowercase, e.g. `1.0e3` not `1.0E3`.",
      category: :formatting,
      example: %{bad: "1.0E3", good: "1.0e3"}
    },
    %{
      id: :no_spaces_in_bitstring_segments,
      title: "No spaces around bitstring segment options",
      description: "Do not put spaces around `::` in bitstring segments, e.g. `<<1::8>>`.",
      category: :formatting,
      example: %{bad: "<<1 ::8>>", good: "<<1::8>>"}
    },
    %{
      id: :fit_collections_on_one_line,
      title: "Fit collections on a single line when they fit",
      description:
        "Collapse a list, map, tuple or call onto one line when it fits within the line length.",
      category: :formatting,
      example: %{bad: "[1,\n2]", good: "[1, 2]"}
    },
    %{
      id: :comments_on_own_line,
      title: "Comments on their own line",
      description:
        "Place a comment on the line above the code it refers to, not trailing after it.",
      category: :formatting,
      example: %{bad: "x = 1 # set x", good: "# set x\nx = 1"}
    },

    # Exceptions.
    %{
      id: :exception_error_suffix,
      title: "Error suffix for exception modules",
      description: "Name exception modules with an `Error` suffix.",
      category: :exceptions,
      example: %{
        bad: "defmodule App.BadInput do\nend",
        good: "defmodule App.BadInputError do\nend"
      }
    },
    %{
      id: :lowercase_exception_messages,
      title: "Lowercase exception messages",
      description: "Begin exception messages with a lowercase letter.",
      category: :exceptions,
      example: %{bad: "raise \"Invalid input\"", good: "raise \"invalid input\""}
    },
    %{
      id: :no_trailing_punctuation_in_exception_messages,
      title: "No trailing punctuation in exception messages",
      description: "Do not end exception messages with punctuation.",
      category: :exceptions,
      example: %{bad: "raise \"invalid input.\"", good: "raise \"invalid input\""}
    },

    # From Lexmag's guide.
    %{
      id: :boolean_operators,
      title: "Use and/or/not for boolean checks",
      description:
        "Use `and`, `or` and `not` for strictly boolean checks; keep `&&`/`||`/`!` for non-boolean values.",
      category: :expressions,
      example: %{bad: "ready && ok", good: "ready and ok"}
    },
    %{
      id: :no_nil_else,
      title: "Omit else that returns nil",
      description: "Omit the `else` branch in `if`/`unless` when it would return `nil`.",
      category: :expressions,
      example: %{bad: "if x, do: a, else: nil", good: "if x, do: a"}
    },
    %{
      id: :concatenation_when_matching_binaries,
      title: "Use <> to match binaries",
      description:
        "Favour the `<>` operator over bitstring syntax when pattern-matching binaries.",
      category: :expressions,
      example: %{bad: "<<\"foo\", rest::binary>> = str", good: "\"foo\" <> rest = str"}
    },
    %{
      id: :parens_on_definition_args,
      title: "Parentheses around definition arguments",
      description:
        "Always use parentheses around arguments to definitions (`def`, `defp`, `defmacro`, …).",
      category: :expressions,
      example: %{bad: "def add a, b do\n  a + b\nend", good: "def add(a, b) do\n  a + b\nend"}
    },
    %{
      id: :snake_case_files,
      title: "snake_case for files and directories",
      description:
        "Name files and directories in snake_case, matching the CamelCase module name.",
      category: :naming,
      example: %{bad: "lib/MyApp/UserProfile.ex", good: "lib/my_app/user_profile.ex"}
    },
    %{
      id: :no_explicit_nil_struct_defaults,
      title: "No explicit nil struct field defaults",
      description:
        "In `defstruct`, list fields that default to `nil` as plain atoms instead of `field: nil`.",
      category: :modules,
      example: %{bad: "defstruct name: nil, age: nil", good: "defstruct [:name, :age]"}
    },
    %{
      id: :parens_on_zero_arity_types,
      title: "Parentheses on zero-arity types",
      description: "Always use parentheses on zero-arity types, e.g. `@type t :: foo()`.",
      category: :typespecs,
      example: %{bad: "@type t :: foo", good: "@type t :: foo()"}
    },
    %{
      id: :consistent_atom_quoting,
      title: "Quote atoms only when required",
      description: "Quote atom literals only when they contain characters that require it.",
      category: :formatting,
      example: %{bad: ":\"valid\"", good: ":valid"}
    },
    %{
      id: :space_before_zero_arity_arrow,
      title: "Space before -> in 0-arity anonymous functions",
      description:
        "Put a space before `->` in zero-arity anonymous functions, e.g. `fn -> :ok end`.",
      category: :formatting,
      example: %{bad: "fn-> :ok end", good: "fn -> :ok end"}
    },
    %{
      id: :spaces_around_default_arguments,
      title: "Spaces around the default-argument operator",
      description: "Surround the `\\\\` default-argument operator with spaces.",
      category: :formatting,
      example: %{bad: "def f(x \\\\0), do: x", good: "def f(x \\\\ 0), do: x"}
    },
    %{
      id: :no_expression_group_alignment,
      title: "Avoid aligning expression groups",
      description:
        "Do not pad consecutive assignments or expressions to align them into columns.",
      category: :formatting,
      example: %{bad: "a   = 1\nbbb = 2", good: "a = 1\nbbb = 2"}
    },
    %{
      id: :pipeline_indentation,
      title: "Single-level pipeline indentation",
      description: "Indent the calls of a multi-line pipeline by a single level.",
      category: :formatting,
      example: %{bad: "x\n    |> f()\n      |> g()", good: "x\n|> f()\n|> g()"}
    },
    %{
      id: :binary_operator_at_line_end,
      title: "Binary operators at end of line",
      description:
        "When breaking a multi-line expression, keep binary operators at the end of each line.",
      category: :formatting,
      example: %{
        bad:
          "value = aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa and bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb and cccccccccccccccccccccccccccccccccccccccc",
        good:
          "value =\n  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa and bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb and\n    cccccccccccccccccccccccccccccccccccccccc"
      }
    },
    %{
      id: :multiline_binary_operand_indentation,
      title: "Indent multi-line binary operands",
      description:
        "Indent the right-hand operand of a multi-line binary operator one level deeper.",
      category: :formatting,
      example: %{bad: "x =\n  foo() +\n  bar()", good: "x =\n  foo() +\n    bar()"}
    },
    %{
      id: :guard_clause_indentation,
      title: "Guard clause indentation",
      description: "Indent a multi-line `when` guard one level deeper than the function head.",
      category: :formatting,
      example: %{
        bad: "def f(x)\nwhen x > 0 do\n  x\nend",
        good: "def f(x)\n    when x > 0 do\n  x\nend"
      }
    },
    %{
      id: :multiline_expression_assignment,
      title: "Multi-line expression on its own line after =",
      description:
        "When assigning a multi-line expression, begin it on a new line after the `=`.",
      category: :formatting,
      example: %{bad: "x = foo()\n    |> bar()", good: "x =\n  foo()\n  |> bar()"}
    },
    %{
      id: :with_clause_indentation,
      title: "with clause indentation",
      description: "Align successive `with` clauses with the first clause.",
      category: :formatting,
      example: %{
        bad: "with {:ok, a} <- f(),\n  {:ok, b} <- g() do\n  a + b\nend",
        good: "with {:ok, a} <- f(),\n     {:ok, b} <- g() do\n  a + b\nend"
      }
    },
    %{
      id: :for_clause_indentation,
      title: "for clause indentation",
      description: "Align successive `for` generators and filters consistently.",
      category: :formatting,
      example: %{
        bad: "for a <- as,\n  b <- bs do\n  {a, b}\nend",
        good: "for a <- as,\n    b <- bs do\n  {a, b}\nend"
      }
    },
    %{
      id: :comments_for_important_details,
      title: "Comments only for important details",
      description:
        "Use comments only to communicate important details the code cannot express itself.",
      category: :comments,
      example: %{
        bad: "# add one to x\nx = x + 1",
        good: "# round half-up for legacy invoices\nx = round_up(x)"
      }
    },
    %{
      id: :no_superfluous_comments,
      title: "Avoid superfluous comments",
      description: "Avoid comments that merely restate what the code already says.",
      category: :comments,
      example: %{bad: "# increment counter\ncounter = counter + 1", good: "counter = counter + 1"}
    },
    %{
      id: :assertion_argument_order,
      title: "Expected value on the right in assertions",
      description:
        "In ExUnit comparison assertions, put the expression under test on the left and the expected value on the right.",
      category: :testing,
      example: %{bad: "assert 200 == status", good: "assert status == 200"}
    },
    %{
      id: :prefer_pattern_matching_over_regex,
      title: "Prefer pattern matching over regular expressions",
      description:
        "Reach for pattern matching and the `String` module before regular expressions.",
      category: :regex,
      example: %{bad: "Regex.match?(~r/^foo/, s)", good: "match?(\"foo\" <> _, s)"}
    },
    %{
      id: :non_capturing_regex_groups,
      title: "Use non-capturing regex groups",
      description: "Use non-capturing groups `(?:...)` when the captured result is not used.",
      category: :regex,
      example: %{bad: "~r/(foo|bar)/", good: "~r/(?:foo|bar)/"}
    },
    %{
      id: :regex_string_anchors,
      title: "Use \\A and \\z for string boundaries",
      description:
        "`^` and `$` match line boundaries; use `\\A` and `\\z` to match the start and end of the whole string.",
      category: :regex,
      example: %{bad: "~r/^foo$/", good: "~r/\\Afoo\\z/"}
    },

    # From Credo's and christopheradams' guides.
    %{
      id: :alias_all_used_modules,
      title: "Alias the modules you use",
      description: "Alias modules you reference repeatedly to keep call sites short.",
      category: :modules,
      example: %{
        bad: "MyApp.Accounts.User.changeset(u)",
        good: "alias MyApp.Accounts.User\nUser.changeset(u)"
      }
    },
    %{
      id: :no_negated_unless,
      title: "No unless with a negated condition",
      description: "Never use `unless` with a negated condition; rewrite as `if`.",
      category: :expressions,
      example: %{bad: "unless not ready do\n  go()\nend", good: "if ready do\n  go()\nend"}
    },
    %{
      id: :no_parens_around_conditionals,
      title: "No parentheses around if/unless conditions",
      description: "Never wrap the condition of `if`/`unless` in parentheses.",
      category: :expressions,
      example: %{bad: "if(ready) do\n  go()\nend", good: "if ready do\n  go()\nend"}
    },
    %{
      id: :no_constant_conditionals,
      title: "No always-true conditionals",
      description:
        "A conditional should not contain an expression that always evaluates the same way.",
      category: :expressions,
      example: %{bad: "if true do\n  go()\nend", good: "go()"}
    },
    %{
      id: :prefer_docs_over_comments,
      title: "Prefer @doc/@moduledoc over comments",
      description: "Favour `@moduledoc`/`@doc` over plain comments for documentation.",
      category: :comments,
      example: %{
        bad: "# Adds two numbers\ndef add(a, b), do: a + b",
        good: "@doc \"Adds two numbers\"\ndef add(a, b), do: a + b"
      }
    },
    %{
      id: :moduledoc_false_when_undocumented,
      title: "@moduledoc false when undocumented",
      description:
        "Give every module a `@moduledoc`, using `@moduledoc false` when it is intentionally undocumented.",
      category: :documentation,
      example: %{
        bad: "defmodule Internal do\nend",
        good: "defmodule Internal do\n  @moduledoc false\nend"
      }
    },
    %{
      id: :blank_line_after_moduledoc,
      title: "Blank line after @moduledoc",
      description: "Separate the code after `@moduledoc` with a single blank line.",
      category: :documentation,
      example: %{bad: "@moduledoc \"X\"\ndef f, do: 1", good: "@moduledoc \"X\"\n\ndef f, do: 1"}
    },
    %{
      id: :annotation_keywords,
      title: "Uppercase annotation keywords (TODO/FIXME/…)",
      description:
        "Mark notes with uppercase annotation keywords followed by a colon, e.g. `TODO:`, `FIXME:`, `OPTIMIZE:`, `HACK:`, `REVIEW:`.",
      category: :comments,
      example: %{bad: "# fix this later", good: "# FIXME: handle the timeout case"}
    },
    %{
      id: :parens_in_function_calls,
      title: "Parentheses on function calls with arguments",
      description:
        "Use parentheses when calling functions with arguments, especially inside pipelines.",
      category: :expressions,
      example: %{bad: "rem 10, 3", good: "rem(10, 3)"}
    },
    %{
      id: :group_function_clauses,
      title: "Group clauses of the same function",
      description: "Keep the clauses of a function with the same name and arity together.",
      category: :modules,
      example: %{
        bad: "def f(1), do: 1\ndef g(), do: 0\ndef f(2), do: 2",
        good: "def f(1), do: 1\ndef f(2), do: 2\n\ndef g(), do: 0"
      }
    },
    %{
      id: :no_iex_pry_in_production,
      title: "No IEx.pry in production code",
      description: "Never leave a call to `IEx.pry/0` in committed code.",
      category: :expressions,
      example: %{bad: "def f(x) do\n  IEx.pry()\n  x\nend", good: "def f(x) do\n  x\nend"}
    },
    %{
      id: :no_io_inspect_in_production,
      title: "No IO.inspect in production code",
      description: "Remove debugging `IO.inspect/2` calls from committed code.",
      category: :expressions,
      example: %{bad: "value |> IO.inspect() |> use()", good: "use(value)"}
    },
    %{
      id: :no_shadowing_kernel_names,
      title: "Don't shadow Kernel functions",
      description: "Avoid naming functions and variables the same as `Kernel` functions.",
      category: :naming,
      example: %{
        bad: "def length(list), do: count(list)",
        good: "def list_length(list), do: count(list)"
      }
    },
    %{
      id: :no_shadowing_stdlib_modules,
      title: "Don't shadow stdlib modules",
      description: "Avoid naming modules the same as standard-library modules.",
      category: :modules,
      example: %{bad: "defmodule String do\nend", good: "defmodule MyApp.Text do\nend"}
    },
    %{
      id: :no_nested_conditionals,
      title: "Don't deeply nest conditionals",
      description: "Never nest `if`, `unless` and `case` more than one level deep.",
      category: :expressions,
      example: %{bad: "if a do\n  if b, do: c\nend", good: "if a and b, do: c"}
    },
    %{
      id: :no_space_after_unary_bang,
      title: "No space after the ! operator",
      description: "Do not put a space after `!` when negating an expression.",
      category: :formatting,
      example: %{bad: "! ready", good: "!ready"}
    },
    %{
      id: :pipe_chains_start_with_raw_value,
      title: "Start pipe chains with a raw value",
      description:
        "Begin a pipe chain with a plain value or variable rather than a function call.",
      category: :expressions,
      example: %{
        bad: "Repo.all(query) |> Enum.map(&f/1)",
        good: "query |> Repo.all() |> Enum.map(&f/1)"
      }
    },
    %{
      id: :prefer_regex_sigil,
      title: "Use the ~r sigil for regexes",
      description: "Use `~r//` as the go-to sigil for regular expressions.",
      category: :regex,
      example: %{bad: "Regex.compile!(\"foo\")", good: "~r/foo/"}
    },
    %{
      id: :vertical_space_for_readability,
      title: "Use vertical space between definitions",
      description: "Use blank lines between definitions and sections to aid readability.",
      category: :formatting,
      example: %{bad: "def a, do: 1\ndef b, do: 2", good: "def a, do: 1\n\ndef b, do: 2"}
    },
    %{
      id: :blank_line_after_multiline_assignment,
      title: "Blank line after a multi-line assignment",
      description: "Add a blank line after a multi-line assignment.",
      category: :formatting,
      example: %{
        bad: "x =\n  foo()\n  |> bar()\ny = 1",
        good: "x =\n  foo()\n  |> bar()\n\ny = 1"
      }
    },
    %{
      id: :alias_self_reference,
      title: "Alias a long module self-reference",
      description: "Use `alias __MODULE__, as: …` for a prettier self-reference.",
      category: :modules,
      example: %{
        bad: "%MyApp.Deeply.Nested.Thing{}",
        good: "alias __MODULE__, as: Thing\n%Thing{}"
      }
    },
    %{
      id: :avoid_metaprogramming,
      title: "Avoid needless metaprogramming",
      description: "Reach for ordinary functions before macros.",
      category: :expressions,
      example: %{
        bad: "defmacro add(a, b), do: quote(do: unquote(a) + unquote(b))",
        good: "def add(a, b), do: a + b"
      }
    },
    %{
      id: :comment_grammar,
      title: "Capitalise and punctuate comments",
      description: "Comments longer than a word are capitalised and use punctuation.",
      category: :comments,
      example: %{bad: "# round the total", good: "# Round the total."}
    },
    %{
      id: :comment_line_length,
      title: "Limit comment lines to 100 characters",
      description: "Keep comment lines within 100 characters.",
      category: :comments,
      example: %{
        bad:
          "# one very long comment line that runs well past the hundred-character limit and keeps going",
        good: "# A shorter comment,\n# wrapped across lines."
      }
    },
    %{
      id: :no_blank_line_after_defmodule,
      title: "No blank line after defmodule",
      description: "Do not leave a blank line immediately after `defmodule … do`.",
      category: :formatting,
      example: %{
        bad: "defmodule A do\n\n  def x, do: 1\nend",
        good: "defmodule A do\n  def x, do: 1\nend"
      }
    },
    %{
      id: :do_colon_for_single_line_if,
      title: "Use do: for single-line if/unless",
      description: "Use the `do:` form for single-line `if`/`unless`.",
      category: :expressions,
      example: %{bad: "if x do\n  a\nend", good: "if x, do: a"}
    },
    %{
      id: :omit_parens_on_zero_arg_defs,
      title: "Omit parentheses on zero-argument definitions",
      description:
        "Use parentheses when a `def` has arguments and omit them when it has none. (Conflicts with the always-parenthesise convention.)",
      category: :expressions,
      example: %{bad: "def go(), do: :ok", good: "def go, do: :ok"}
    },
    %{
      id: :no_space_before_call_parens,
      title: "No space between a function name and (",
      description: "Never put a space between a function name and its opening parenthesis.",
      category: :formatting,
      example: %{bad: "foo (x)", good: "foo(x)"}
    },
    %{
      id: :heredocs_for_documentation,
      title: "Use heredocs for documentation",
      description: "Use markdown heredocs for `@doc`/`@moduledoc` content.",
      category: :documentation,
      example: %{
        bad: "@doc \"line one\\nline two\"",
        good: "@doc \"\"\"\nline one\nline two\n\"\"\""
      }
    },
    %{
      id: :keyword_list_special_syntax,
      title: "Use keyword-list shorthand",
      description: "Always use the special `key: value` syntax for keyword lists.",
      category: :expressions,
      example: %{bad: "[{:a, 1}, {:b, 2}]", good: "[a: 1, b: 2]"}
    },
    %{
      id: :long_do_clause_on_new_line,
      title: "Long do: clause on its own line",
      description:
        "When a function head and `do:` clause are too long for one line, put `do:` on a new line.",
      category: :formatting,
      example: %{
        bad: "def handle(arg), do: a_rather_long_expression_that_overflows(arg)",
        good: "def handle(arg),\n  do: a_rather_long_expression_that_overflows(arg)"
      }
    },
    %{
      id: :verbose_map_syntax_for_mixed_keys,
      title: "Verbose map syntax for non-atom keys",
      description: "If any map key is not an atom, use the verbose `=>` syntax for every key.",
      category: :expressions,
      example: %{bad: "%{\"b\" => 2, a: 1}", good: "%{\"b\" => 2, :a => 1}"}
    },
    %{
      id: :shorthand_map_syntax_for_atom_keys,
      title: "Shorthand map syntax for atom keys",
      description: "Use the `key: value` shorthand when all map keys are atoms.",
      category: :expressions,
      example: %{bad: "%{:a => 1, :b => 2}", good: "%{a: 1, b: 2}"}
    },
    %{
      id: :module_name_matches_path,
      title: "Module name mirrors its file path",
      description: "Represent each level of module nesting as a directory in the file path.",
      category: :modules,
      example: %{
        bad: "lib/parser.ex defining MyApp.Lexer.Parser",
        good: "lib/my_app/lexer/parser.ex defining MyApp.Lexer.Parser"
      }
    },
    %{
      id: :always_moduledoc,
      title: "Always include @moduledoc",
      description: "Include a `@moduledoc` on the line right after `defmodule`.",
      category: :documentation,
      example: %{
        bad: "defmodule X do\n  def f, do: 1\nend",
        good: "defmodule X do\n  @moduledoc \"…\"\n  def f, do: 1\nend"
      }
    },
    %{
      id: :multiline_case_clause_blank_lines,
      title: "Blank lines around multi-line case clauses",
      description:
        "If any `case`/`cond` clause needs more than one line, separate all clauses with blank lines.",
      category: :formatting,
      example: %{
        bad: "case x do\n  1 -> a\n  2 ->\n    b\nend",
        good: "case x do\n  1 ->\n    a\n\n  2 ->\n    b\nend"
      }
    },
    %{
      id: :multiline_collection_one_per_line,
      title: "One element per line in multi-line collections",
      description:
        "If a list, map or struct spans multiple lines, put each element on its own line.",
      category: :formatting,
      example: %{bad: "[\n  1, 2,\n  3\n]", good: "[\n  1,\n  2,\n  3\n]"}
    },
    %{
      id: :multiline_assign_bracket_placement,
      title: "Opening bracket stays on the assignment line",
      description:
        "When assigning a multi-line list/map/struct, keep the opening bracket on the first line.",
      category: :formatting,
      example: %{bad: "x =\n  [\n    1,\n    2\n  ]", good: "x = [\n  1,\n  2\n]"}
    },
    %{
      id: :no_single_line_def_among_multiline,
      title: "Consistent def line style",
      description:
        "If a function has more than one multi-line clause, don't mix in single-line `def`s.",
      category: :modules,
      example: %{
        bad: "def f(0), do: 0\n\ndef f(n) do\n  n + 1\nend",
        good: "def f(0) do\n  0\nend\n\ndef f(n) do\n  n + 1\nend"
      }
    },
    %{
      id: :main_type_named_t,
      title: "Name the main type t",
      description: "Name a module's main type `t`.",
      category: :typespecs,
      example: %{bad: "@type user :: map()", good: "@type t :: map()"}
    },
    %{
      id: :one_module_per_file,
      title: "One module per file",
      description:
        "Define one module per file unless a module is only used internally by another.",
      category: :modules,
      example: %{
        bad: "defmodule A do\nend\n\ndefmodule B do\nend",
        good: "# A and B in separate files"
      }
    },
    %{
      id: :parens_on_piped_calls,
      title: "Parentheses on piped one-arity calls",
      description: "Use parentheses for one-arity functions when used in a pipeline.",
      category: :expressions,
      example: %{bad: "x |> Enum.reverse", good: "x |> Enum.reverse()"}
    },
    %{
      id: :predicate_guard_is_prefix,
      title: "is_ prefix for guard-safe predicates",
      description: "Name boolean checks usable in guards with an `is_` prefix (no trailing `?`).",
      category: :naming,
      example: %{bad: "defguard valid?(x) when x > 0", good: "defguard is_valid(x) when x > 0"}
    },
    %{
      id: :no_private_fn_same_name_as_public,
      title: "Private function names differ from public",
      description: "Private functions should not share a name with public functions.",
      category: :naming,
      example: %{
        bad: "def f(x), do: x\ndefp f(x, y), do: x + y",
        good: "def f(x), do: x\ndefp do_f(x, y), do: x + y"
      }
    },
    %{
      id: :no_repetitive_module_names,
      title: "Avoid repetitive module names",
      description: "Avoid repeating fragments across a module's namespace.",
      category: :modules,
      example: %{bad: "MyApp.User.UserHelper", good: "MyApp.User.Helper"}
    },
    %{
      id: :spec_directly_before_function,
      title: "@spec directly before the function",
      description: "Place a `@spec` on the line directly before the function it describes.",
      category: :typespecs,
      example: %{
        bad: "@spec f() :: :ok\n\ndef f, do: :ok",
        good: "@spec f() :: :ok\ndef f, do: :ok"
      }
    },
    %{
      id: :omit_defstruct_brackets,
      title: "Omit brackets from a defstruct keyword list",
      description: "Omit the square brackets when the argument to `defstruct` is a keyword list.",
      category: :modules,
      example: %{bad: "defstruct [name: nil, age: 0]", good: "defstruct name: nil, age: 0"}
    },
    %{
      id: :group_typedoc_with_type,
      title: "Keep @typedoc with its @type",
      description: "Place `@typedoc` and `@type` definitions together.",
      category: :typespecs,
      example: %{
        bad: "@type t :: map()\n# …later…\n@typedoc \"a thing\"",
        good: "@typedoc \"a thing\"\n@type t :: map()"
      }
    },
    %{
      id: :multiline_union_type,
      title: "One part per line in long union types",
      description: "If a union type is too long for one line, put each part on its own line.",
      category: :typespecs,
      example: %{
        bad:
          "@type t :: :aaaaa | :bbbbb | :ccccc | :ddddd | :eeeee | :fffff | :ggggg | :hhhhh | :iiiii | :jjjjj | :kkkkk",
        good:
          "@type t ::\n        :aaaaa\n        | :bbbbb\n        | :ccccc\n        | :ddddd\n        | :eeeee\n        | :fffff\n        | :ggggg\n        | :hhhhh\n        | :iiiii\n        | :jjjjj\n        | :kkkkk"
      }
    },
    %{
      id: :with_else_formatting,
      title: "Format with/else over multiple lines",
      description:
        "When a `with` has a multi-line `do` block, format its `else` clauses on their own lines.",
      category: :expressions,
      example: %{
        bad: "with {:ok, x} <- f() do\n  x\nelse _ -> :error end",
        good: "with {:ok, x} <- f() do\n  x\nelse\n  _ -> :error\nend"
      }
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
