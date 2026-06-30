defmodule GreenValidation.MixFormatProbeTest do
  use ExUnit.Case, async: true

  alias GreenValidation.MixFormatProbe

  describe "classify/1" do
    test "is :enforced when the formatter turns input into expected" do
      assert MixFormatProbe.classify(%{input: "1+1\n", expected: "1 + 1\n"}) == :enforced
    end

    test "is :not_enforced when the formatter leaves the input unchanged" do
      assert MixFormatProbe.classify(%{input: ":fooBar\n", expected: ":foo_bar\n"}) ==
               :not_enforced
    end

    test "is :indeterminate when the formatter produces a third form" do
      assert MixFormatProbe.classify(%{input: "1+1", expected: "1+1"}) == :indeterminate
    end

    test "is :indeterminate when the input cannot be parsed" do
      assert MixFormatProbe.classify(%{input: "%{", expected: "%{}"}) == :indeterminate
    end

    test "is :indeterminate when the expected form is not idempotent" do
      assert MixFormatProbe.classify(%{input: "a=1", expected: "a=1"}) == :indeterminate
    end
  end

  describe "classify/1 with a :file-level probe" do
    test "mirrors the format task appending a trailing newline" do
      assert MixFormatProbe.classify(%{input: "x = 1", expected: "x = 1\n", level: :file}) ==
               :enforced
    end
  end

  describe "enforced?/1" do
    test "is true only when classify is :enforced" do
      assert MixFormatProbe.enforced?(%{input: "1+1", expected: "1 + 1"})
      refute MixFormatProbe.enforced?(%{input: ":fooBar", expected: ":foo_bar"})
    end
  end
end
