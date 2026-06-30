defmodule GreenValidation.Sources.LexmagTest do
  use ExUnit.Case, async: true

  alias GreenValidation.Sources.Lexmag
  alias GreenValidation.StyleCatalog

  describe "mapping/0" do
    test "is not empty" do
      assert length(Lexmag.mapping()) > 0
    end

    test "references only valid master rule ids" do
      for {id, _anchor} <- Lexmag.mapping() do
        valid? = StyleCatalog.valid_id?(id)
        assert valid?, "#{id} is not a master rule id"
      end
    end

    test "every mapped anchor is a non-empty string" do
      for {_id, anchor} <- Lexmag.mapping() do
        assert is_binary(anchor) and anchor != ""
      end
    end

    test "maps no_semicolons to the no-semicolon anchor" do
      assert {:no_semicolons, "no-semicolon"} in Lexmag.mapping()
    end

    test "maps no_trailing_comma to the trailing-comma anchor" do
      assert {:no_trailing_comma, "trailing-comma"} in Lexmag.mapping()
    end

    test "maps the bitstring-segment-options anchor to the existing master rule" do
      assert {:no_spaces_in_bitstring_segments, "bitstring-segment-options"} in Lexmag.mapping()
    end

    test "maps no_space_after_unary_bang (no-spaces-in-code also covers unary operators)" do
      assert {:no_space_after_unary_bang, "no-spaces-in-code"} in Lexmag.mapping()
    end

    test "covers the formerly-unmapped Lexmag anchors" do
      anchors = Enum.map(Lexmag.mapping(), &elem(&1, 1))

      for anchor <- ~w(boolean-operators no-nil-else patterns-matching-binaries
                       snake-case-dirs-files fun-parens quotes-around-atoms
                       default-arguments pattern-matching-over-regexp critical-comments
                       exunit-assertion-side pipeline-indentation expression-group-alignment) do
        assert anchor in anchors, "Lexmag anchor #{anchor} is not mapped"
      end
    end

    test "maps no_parens_around_anonymous_fn_args to the anonymous-fun-parens anchor" do
      assert {:no_parens_around_anonymous_fn_args, "anonymous-fun-parens"} in Lexmag.mapping()
    end
  end
end
