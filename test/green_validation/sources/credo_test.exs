defmodule GreenValidation.Sources.CredoTest do
  use ExUnit.Case, async: true

  alias GreenValidation.Sources.Credo
  alias GreenValidation.StyleCatalog

  describe "mapping/0" do
    test "is not empty" do
      assert length(Credo.mapping()) > 0
    end

    test "references only valid master rule ids" do
      for {id, _anchor} <- Credo.mapping() do
        valid? = StyleCatalog.valid_id?(id)
        assert valid?, "#{id} is not a master rule id"
      end
    end

    test "every mapped anchor is a non-empty string" do
      for {_id, anchor} <- Credo.mapping() do
        assert is_binary(anchor) and anchor != ""
      end
    end

    test "maps no_spaces_inside_brackets to the spaces-braces anchor" do
      assert {:no_spaces_inside_brackets, "spaces-braces"} in Credo.mapping()
    end

    test "maps no_semicolons to the semicolon-between-statements anchor" do
      assert {:no_semicolons, "semicolon-between-statements"} in Credo.mapping()
    end

    test "covers the formerly-unmapped Credo anchors" do
      anchors = Enum.map(Credo.mapping(), &elem(&1, 1))

      for anchor <- ~w(caret-and-dollar-regex function-parens multi-line-call alias-modules
                       avoid-double-negations no-nested-conditionals iex-pry io-inspect
                       pipe-chains no-space-bang doc-false fixme todo) do
        assert anchor in anchors, "Credo anchor #{anchor} is not mapped"
      end
    end
  end
end
