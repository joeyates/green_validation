defmodule GreenValidation.StyleCatalogTest do
  use ExUnit.Case, async: true

  alias GreenValidation.StyleCatalog

  describe "all/0" do
    test "returns a non-empty list of rules" do
      assert length(StyleCatalog.all()) > 0
    end

    test "every rule has an atom id, a title, a description and a category" do
      for rule <- StyleCatalog.all() do
        assert is_atom(rule.id)
        assert is_binary(rule.title) and rule.title != ""
        assert is_binary(rule.description) and rule.description != ""
        assert is_atom(rule.category)
      end
    end

    test "ids are unique" do
      ids = Enum.map(StyleCatalog.all(), & &1.id)

      assert ids == Enum.uniq(ids)
    end

    test "every rule has a bad and good example" do
      for rule <- StyleCatalog.all() do
        assert is_binary(rule.example.bad) and rule.example.bad != ""
        assert is_binary(rule.example.good) and rule.example.good != ""
        assert rule.example.bad != rule.example.good
      end
    end
  end

  describe "ids/0" do
    test "returns every rule id" do
      assert StyleCatalog.ids() == Enum.map(StyleCatalog.all(), & &1.id)
    end
  end

  describe "valid_id?/1" do
    test "is true for a known id" do
      known = StyleCatalog.all() |> hd() |> Map.fetch!(:id)

      assert StyleCatalog.valid_id?(known)
    end

    test "is false for an unknown id" do
      refute StyleCatalog.valid_id?(:definitely_not_a_rule)
    end
  end
end
