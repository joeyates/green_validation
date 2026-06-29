defmodule GreenValidation.Sources.MixFormat do
  @moduledoc """
  Empirical analysis of which master rules `mix format` enforces.

  Each master rule that is plausibly a whitespace/token/layout concern has a probe
  (`%{id, input, expected, reference}`). `analyze/0` runs every probe through
  `GreenValidation.MixFormatProbe` and reports `proposed: true/false` per rule — never
  hand-set. Probes for rules the formatter is expected to ignore are included on purpose:
  the negative results are what make the cross-source comparison meaningful.

  Candidates were harvested from Elixir's own source — the `@doc` for
  `Code.format_string!/2` in `code.ex` and the attribute tables in `code/formatter.ex` —
  then verified here against the real formatter.

  `analyze/0` also runs a small corpus through the formatter and reports transformations
  that no probe accounts for as `unmapped`, feeding the refinement loop (add a master
  rule, add a probe, re-run).
  """

  alias GreenValidation.MixFormatProbe

  @probes [
    # Enforced by the formatter.
    %{
      id: :spaces_around_binary_operators,
      input: "1+1",
      expected: "1 + 1",
      reference: "code/formatter.ex — binary operator spacing"
    },
    %{
      id: :no_spaces_around_range_operator,
      input: "1 .. 2",
      expected: "1..2",
      reference: "code/formatter.ex @no_space_binary_operators"
    },
    %{
      id: :spaces_after_commas,
      input: "[1,2,3]",
      expected: "[1, 2, 3]",
      reference: "code/formatter.ex — collection element spacing"
    },
    %{
      id: :no_spaces_inside_brackets,
      input: "[ 1, 2 ]",
      expected: "[1, 2]",
      reference: "code/formatter.ex — no padding inside brackets/braces/parens"
    },
    %{
      id: :no_semicolons,
      input: "a = 1; b = 2",
      expected: "a = 1\nb = 2",
      reference: "code.ex Code.format_string!/2 docs — statements split onto separate lines"
    },
    %{
      id: :no_trailing_comma,
      input: "[1, 2,]",
      expected: "[1, 2]",
      reference: "code/formatter.ex — trailing comma removed from single-line collections"
    },
    %{
      id: :omit_keyword_list_brackets,
      input: "foo([a: 1])",
      expected: "foo(a: 1)",
      reference: "code/formatter.ex — optional keyword-list brackets omitted"
    },
    %{
      id: :spaces_around_arrow,
      input: "fn x->x end",
      expected: "fn x -> x end",
      reference: "code/formatter.ex — spaces around the -> operator"
    },
    %{
      id: :capture_operator_spacing,
      input: "&(&1)",
      expected: "& &1",
      reference: "code/formatter.ex — capture operator spacing and parens"
    },
    %{
      id: :no_parens_around_anonymous_fn_args,
      input: "fn(x) -> x end",
      expected: "fn x -> x end",
      reference: "code/formatter.ex — anonymous function argument parens removed"
    },
    %{
      id: :no_redundant_parentheses,
      input: "(1 + 2)",
      expected: "1 + 2",
      reference: "code/formatter.ex — redundant grouping parentheses removed"
    },
    %{
      id: :lowercase_exponent,
      input: "1.0E3",
      expected: "1.0e3",
      reference: "code.ex Code.format_string!/2 docs — number normalisation"
    },
    %{
      id: :no_spaces_in_bitstring_segments,
      input: "<<1 ::8>>",
      expected: "<<1::8>>",
      reference: "code/formatter.ex @no_space_binary_operators (bitstring segments)"
    },
    %{
      id: :fit_collections_on_one_line,
      input: "[1,\n2]",
      expected: "[1, 2]",
      reference: "code.ex Code.format_string!/2 docs — fit on a single line when possible"
    },
    %{
      id: :comments_on_own_line,
      input: "x = 1 # foo",
      expected: "# foo\nx = 1",
      reference:
        "code.ex Code.format_string!/2 docs — trailing comments hoisted to their own line"
    },
    %{
      id: :comment_leading_space,
      input: "#x",
      expected: "# x",
      reference: "code.ex Code.format_string!/2 docs — Code comments"
    },
    %{
      id: :digit_grouping_underscores,
      input: "1000000",
      expected: "1_000_000",
      reference: "code.ex Code.format_string!/2 docs — Keeping user's formatting (numbers)"
    },
    %{
      id: :uppercase_hex_literals,
      input: "0xabcd",
      expected: "0xABCD",
      reference: "code.ex Code.format_string!/2 docs — Keeping user's formatting (numbers)"
    },
    %{
      id: :collapse_consecutive_blank_lines,
      input: "a = 1\n\n\n\nb = 2",
      expected: "a = 1\n\nb = 2",
      reference: "code.ex Code.format_string!/2 docs — Keeping user's formatting (newlines)"
    },
    %{
      id: :unix_line_endings,
      input: "a = 1\r\nb = 2",
      expected: "a = 1\nb = 2",
      reference: "code.ex Code.format_string!/2 docs — Newlines converted to \\n"
    },

    # Not enforced by the formatter (it never changes names or semantics by default).
    %{
      id: :snake_case_atoms_and_variables,
      input: ":fooBar",
      expected: ":foo_bar",
      reference: "code.ex Code.format_string!/2 docs — does not hard code names"
    },
    %{
      id: :pipeline_for_chains,
      input: "foo(bar(x))",
      expected: "x |> bar() |> foo()",
      reference: "code.ex Code.format_string!/2 docs — never changes semantics"
    }
  ]

  # Snippets used to detect formatter behaviour not covered by a probe. Snippets that are
  # a probe's input are excluded (already covered); the rest, if the formatter changes
  # them, are reported as `unmapped` — candidates for a new master rule.
  #
  # The long call is the one deliberately-uncovered entry: it exercises the formatter's
  # fit-or-break line wrapping, which is emergent layout (the `Inspect.Algebra` engine)
  # rather than a discrete rule, so it stays in `unmapped` as a reminder of that gap.
  @corpus [
    "1+1",
    "1.0E3",
    "foo(aaaaaaaaaa, bbbbbbbbbb, cccccccccc, dddddddddd, eeeeeeeeee, ffffffffff, gggggggggg, hhhhhhhhhh)"
  ]

  @doc """
  Returns the probe table.
  """
  @spec probes() :: [
          %{id: atom(), input: String.t(), expected: String.t(), reference: String.t()}
        ]
  def probes(), do: @probes

  @doc """
  Runs every probe and the gap sweep, returning `%{rules: [...], unmapped: [...]}`.
  """
  @spec analyze() :: %{rules: [map()], unmapped: [map()]}
  def analyze() do
    rules =
      Enum.map(@probes, fn probe ->
        enforced? = MixFormatProbe.enforced?(probe)

        %{
          id: probe.id,
          proposed: enforced?,
          status: if(enforced?, do: "enforced", else: "not_enforced"),
          reference: probe.reference
        }
      end)

    %{rules: rules, unmapped: gaps()}
  end

  defp gaps() do
    probe_inputs = MapSet.new(@probes, & &1.input)

    @corpus
    |> Enum.reject(&MapSet.member?(probe_inputs, &1))
    |> Enum.map(fn snippet -> {snippet, format(snippet)} end)
    |> Enum.filter(fn {snippet, formatted} -> formatted != snippet end)
    |> Enum.map(fn {snippet, formatted} -> %{before: snippet, after: formatted} end)
  end

  defp format(string) do
    string
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end
end
