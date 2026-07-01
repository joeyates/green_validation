defmodule GreenValidation.ComparisonPdfTest do
  use ExUnit.Case, async: true

  alias GreenValidation.ComparisonPdf

  @comparison %{
    "generated_with" => %{"elixir_version" => "1.19.5"},
    "sources" => [
      %{"id" => "mix_format", "name" => "mix format", "repo_url" => "https://example.com/mf"},
      %{
        "id" => "lexmag",
        "name" => "Lexmag's Elixir Style Guide",
        "repo_url" => "https://example.com/lex"
      }
    ],
    "rules" => [
      %{
        "id" => "spaces_around_binary_operators",
        "title" => "Spaces around binary operators",
        "category" => "formatting",
        "example" => %{"bad" => "1+1", "good" => "1 + 1"},
        "proposed_by" => ["mix_format", "lexmag"],
        "sources" => %{
          "mix_format" => %{
            "proposed" => true,
            "reference" => "formatter.ex",
            "status" => "enforced"
          },
          "lexmag" => %{"proposed" => true, "reference" => "https://example.com/lex#spaces"}
        }
      },
      %{
        "id" => "snake_case_atoms_and_variables",
        "title" => "snake_case",
        "category" => "naming",
        "example" => %{"bad" => "fooBar", "good" => "foo_bar"},
        "proposed_by" => ["lexmag"],
        "sources" => %{
          "mix_format" => %{"proposed" => false, "status" => "not_enforced"},
          "lexmag" => %{"proposed" => true, "reference" => "https://example.com/lex#snake"}
        }
      }
    ],
    "rules_with_no_source" => ["alphabetical_alias_order"]
  }

  describe "rows/1" do
    test "the header row is Rule plus a label per guide (no mix format column)" do
      [header | _] = ComparisonPdf.rows(@comparison)

      assert header == ["Rule", "Lexmag"]
    end

    test "marks guide proposals with Yes; the rule cell carries no mix format column" do
      [_header, spaces_row, snake_row] = ComparisonPdf.rows(@comparison)

      assert spaces_row == ["Spaces around binary operators", "Yes"]
      assert snake_row == ["snake_case", "Yes"]
    end
  end

  describe "sections/1" do
    test "puts mix-format-enforced rules first, then a section per category" do
      sections = ComparisonPdf.sections(@comparison)

      assert Enum.map(sections, &elem(&1, 0)) == ["Enforced by mix format", "Naming"]
    end

    test "groups the rules into the right blocks" do
      [{_enforced_title, enforced}, {_naming_title, naming}] = ComparisonPdf.sections(@comparison)

      assert Enum.map(enforced, & &1["id"]) == ["spaces_around_binary_operators"]
      assert Enum.map(naming, & &1["id"]) == ["snake_case_atoms_and_variables"]
    end

    test "sorts the Enforced-by-mix-format block by category then title" do
      comparison = %{
        "sources" => [%{"id" => "mix_format", "name" => "mix format", "repo_url" => "x"}],
        "rules" => [
          enforced_rule("z_fmt", "Z rule", "formatting"),
          enforced_rule("a_name", "A rule", "naming"),
          enforced_rule("a_fmt", "A rule", "formatting")
        ],
        "rules_with_no_source" => []
      }

      [{"Enforced by mix format", rules}] = ComparisonPdf.sections(comparison)

      assert Enum.map(rules, & &1["id"]) == ["a_fmt", "z_fmt", "a_name"]
    end

    test "sorts the rules within a section alphabetically by title" do
      comparison = %{
        "sources" => [%{"id" => "mix_format", "name" => "mix format", "repo_url" => "x"}],
        "rules" => [
          rule("zebra", "Zebra rule", "naming"),
          rule("apple", "Apple rule", "naming"),
          rule("mango", "mango rule", "naming")
        ],
        "rules_with_no_source" => []
      }

      [{"Naming", rules}] = ComparisonPdf.sections(comparison)

      assert Enum.map(rules, & &1["title"]) == ["Apple rule", "mango rule", "Zebra rule"]
    end
  end

  describe "example_sections/1" do
    test "groups every rule by category with no separate Enforced block" do
      sections = ComparisonPdf.example_sections(@comparison)

      assert Enum.map(sections, &elem(&1, 0)) == ["Formatting", "Naming"]
    end

    test "keeps mix-format-enforced rules in their own category" do
      [{"Formatting", formatting}, _naming] = ComparisonPdf.example_sections(@comparison)

      assert Enum.map(formatting, & &1["id"]) == ["spaces_around_binary_operators"]
    end
  end

  describe "notes/1" do
    test "numbers parameter-disagreement notes in table order" do
      comparison = %{
        "sources" => [
          %{"id" => "mix_format", "name" => "mix format", "repo_url" => "x"},
          %{"id" => "credo", "name" => "Credo", "repo_url" => "y"}
        ],
        "rules" => [
          %{
            "id" => "max_line_length",
            "title" => "Maximum line length",
            "category" => "formatting",
            "example" => %{"bad" => "a", "good" => "b"},
            "proposed_by" => ["mix_format", "credo"],
            "sources" => %{
              "mix_format" => %{"proposed" => true, "status" => "enforced", "note" => "98 cols"},
              "credo" => %{"proposed" => true, "note" => "80 cols"}
            }
          }
        ],
        "rules_with_no_source" => []
      }

      notes = ComparisonPdf.notes(comparison)

      assert Enum.map(notes, & &1.number) == [1, 2]
      assert Enum.map(notes, & &1.note) == ["98 cols", "80 cols"]
    end
  end

  describe "render/1" do
    test "produces PDF bytes" do
      pdf = ComparisonPdf.render(@comparison)

      assert is_binary(pdf)
      assert String.starts_with?(pdf, "%PDF-")
      assert byte_size(pdf) > 500
    end
  end

  describe "render/2" do
    test "embeds the git version and generation date in the intro" do
      pdf = ComparisonPdf.render(@comparison, version: "abc1234", generated_on: ~D[2026-06-30])

      assert pdf =~ "abc1234"
      assert pdf =~ "2026-06-30"
    end
  end

  defp rule(id, title, category) do
    %{
      "id" => id,
      "title" => title,
      "category" => category,
      "example" => %{"bad" => "bad", "good" => "good"},
      "proposed_by" => [],
      "sources" => %{"mix_format" => %{"proposed" => false, "status" => "not_enforced"}}
    }
  end

  defp enforced_rule(id, title, category) do
    %{
      rule(id, title, category)
      | "proposed_by" => ["mix_format"],
        "sources" => %{"mix_format" => %{"proposed" => true, "status" => "enforced"}}
    }
  end
end
