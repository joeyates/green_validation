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
        id |> StyleCatalog.valid_id?() |> assert "#{id} is not a master rule id"
      end
    end

    test "every mapped anchor is a non-empty string" do
      for {_id, anchor} <- Lexmag.mapping() do
        assert is_binary(anchor) and anchor != ""
      end
    end
  end
end
