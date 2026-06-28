defmodule GreenValidation.MixFormatProbeTest do
  use ExUnit.Case, async: true

  alias GreenValidation.MixFormatProbe

  describe "enforced?/1" do
    test "is true when the formatter transforms input into expected" do
      assert MixFormatProbe.enforced?(%{input: "1+1\n", expected: "1 + 1\n"})
    end

    test "is false when the formatter leaves the input unchanged" do
      refute MixFormatProbe.enforced?(%{input: ":fooBar\n", expected: ":foo_bar\n"})
    end

    test "raises for a non-isolated probe (formatter produces a third form)" do
      assert_raise ArgumentError, fn ->
        MixFormatProbe.enforced?(%{input: "1+1", expected: "1+1"})
      end
    end
  end
end
