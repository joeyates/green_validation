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
    test "the header row is Rule plus a short label per source" do
      [header | _] = ComparisonPdf.rows(@comparison)

      assert header == ["Rule", "mix format", "Lexmag"]
    end

    test "shows Enforced for mix format and Yes for a guide; blank otherwise" do
      [_header, spaces_row, snake_row] = ComparisonPdf.rows(@comparison)

      assert spaces_row == ["Spaces around binary operators", "Enforced", "Yes"]
      assert snake_row == ["snake_case", "", "Yes"]
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

  describe "render/1" do
    test "produces PDF bytes" do
      pdf = ComparisonPdf.render(@comparison)

      assert is_binary(pdf)
      assert String.starts_with?(pdf, "%PDF-")
      assert byte_size(pdf) > 500
    end
  end

  defp rule(id, title, category) do
    %{
      "id" => id,
      "title" => title,
      "category" => category,
      "proposed_by" => [],
      "sources" => %{"mix_format" => %{"proposed" => false, "status" => "not_enforced"}}
    }
  end
end
