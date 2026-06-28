defmodule GreenValidation.StyleSourceTest do
  use ExUnit.Case, async: true

  alias GreenValidation.StyleSource

  describe "all/0" do
    test "returns the four sources, each with id and name" do
      sources = StyleSource.all()
      ids = sources |> Enum.map(& &1.id) |> Enum.sort()

      assert ids == [:christopher_adams, :credo, :lexmag, :mix_format]

      for source <- sources do
        assert is_binary(source.name) and source.name != ""
      end
    end
  end

  describe "prose/0" do
    test "returns the three fetchable guides, each with a raw_url" do
      prose = StyleSource.prose()
      ids = prose |> Enum.map(& &1.id) |> Enum.sort()

      assert ids == [:christopher_adams, :credo, :lexmag]

      for source <- prose do
        assert is_binary(source.raw_url)
      end
    end

    test "excludes mix_format" do
      refute Enum.any?(StyleSource.prose(), &(&1.id == :mix_format))
    end
  end
end
