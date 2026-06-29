defmodule GreenValidation.Sources.ChristopherAdamsTest do
  use ExUnit.Case, async: true

  alias GreenValidation.Sources.ChristopherAdams
  alias GreenValidation.StyleCatalog

  describe "mapping/0" do
    test "is not empty" do
      assert length(ChristopherAdams.mapping()) > 0
    end

    test "references only valid master rule ids" do
      for {id, _anchor} <- ChristopherAdams.mapping() do
        id |> StyleCatalog.valid_id?() |> assert "#{id} is not a master rule id"
      end
    end

    test "every mapped anchor is a non-empty string" do
      for {_id, anchor} <- ChristopherAdams.mapping() do
        assert is_binary(anchor) and anchor != ""
      end
    end

    test "maps no_spaces_inside_brackets to the spaces anchor" do
      assert {:no_spaces_inside_brackets, "spaces"} in ChristopherAdams.mapping()
    end

    test "maps omit_keyword_list_brackets to the keyword-list-brackets anchor" do
      assert {:omit_keyword_list_brackets, "keyword-list-brackets"} in ChristopherAdams.mapping()
    end

    test "maps comments_on_own_line to the comments-above-line anchor" do
      assert {:comments_on_own_line, "comments-above-line"} in ChristopherAdams.mapping()
    end

    test "maps alphabetical_alias_order to the module-attribute-ordering anchor" do
      assert {:alphabetical_alias_order, "module-attribute-ordering"} in ChristopherAdams.mapping()
    end
  end
end
