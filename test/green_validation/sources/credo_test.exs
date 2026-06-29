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
        id |> StyleCatalog.valid_id?() |> assert "#{id} is not a master rule id"
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
  end
end
