defmodule GreenValidation.ChangeTest do
  use ExUnit.Case, async: true

  alias GreenValidation.Change

  describe "line_numbers/1" do
    test "extracts the line numbers of changed lines from a mix format diff" do
      diff = """
       1  1  |defmodule Foo do
       2  2  |  def bar do
       3    -|      1+1
          3 +|    1 + 1
       4  4  |  end
       5  5  |
       6  6  |  def baz do
       7    -|    x=2
          7 +|    x = 2
       8  8  |    x
       9  9  |  end
      """

      change = %Change{path: "lib/foo.ex", diff: diff}

      assert Change.line_numbers(change) == [3, 7]
    end

    test "returns an empty list when the diff has no changed lines" do
      change = %Change{path: "lib/foo.ex", diff: ""}

      assert Change.line_numbers(change) == []
    end

    test "deduplicates and sorts the line numbers" do
      diff = """
          3 +|    a = 1
       3    -|      a=1
       1    -|x
          1 +|x = 0
      """

      change = %Change{path: "lib/foo.ex", diff: diff}

      assert Change.line_numbers(change) == [1, 3]
    end
  end
end
