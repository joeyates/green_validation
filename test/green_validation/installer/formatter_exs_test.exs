defmodule GreenValidation.Installer.FormatterExsTest do
  use ExUnit.Case, async: true

  import GreenValidation.Installer.FormatterExs

  describe "update_formatter_exs_code/2" do
    test "adds new key-value pair to empty formatter" do
      code = """
      []
      """

      updated_code = update_formatter_exs_code(code, new_key: "new_value")

      assert updated_code == """
             [new_key: "new_value"]
             """
    end

    test "adds a new pair to a Keyword" do
      code = """
      [existing_key: "value"]
      """

      updated_code = update_formatter_exs_code(code, new_key: "new_value")

      assert updated_code == """
             [existing_key: "value", new_key: "new_value"]
             """
    end

    test "updates existing pair in a Keyword" do
      code = """
      [existing_key: "old_value", another_key: "another_value"]
      """

      updated_code = update_formatter_exs_code(code, existing_key: "new_value")

      assert updated_code == """
             [existing_key: "new_value", another_key: "another_value"]
             """
    end

    test "adds a new pair to a Keyword preceded by other code" do
      code = """
      foo = [pizza: "delicious"]

      [
        existing_key: "value",
        foo: foo
      ]
      """

      updated_code = update_formatter_exs_code(code, new_key: "new_value")

      assert updated_code == """
             foo = [pizza: "delicious"]

             [
               existing_key: "value",
               foo: foo,
               new_key: "new_value"
             ]
             """
    end

    test "updates existing pair in a Keyword preceded by other code" do
      code = """
      foo = [pizza: "delicious"]

      [
        existing_key: "old_value",
        foo: foo
      ]
      """

      updated_code = update_formatter_exs_code(code, existing_key: "new_value")

      assert updated_code == """
             foo = [pizza: "delicious"]

             [
               existing_key: "new_value",
               foo: foo
             ]
             """
    end

    test "preserves formatting and comments" do
      code = """
      # Comment about the formatter
      [
        existing_key: "old_value"
        # Another comment
      ]
      """

      updated_code = update_formatter_exs_code(code, existing_key: "new_value")

      assert updated_code == """
             # Comment about the formatter
             [
               existing_key: "new_value"
               # Another comment
             ]
             """
    end
  end
end
