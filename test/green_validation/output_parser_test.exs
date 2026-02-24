defmodule GreenValidation.OutputParserTest do
  use ExUnit.Case, async: true

  import GreenValidation.OutputParser

  alias GreenValidation.RuleResult

  describe "parse_output/2" do
    test "extracts file paths from warnings" do
      output = """
      5 | Some text
      └─ config/my_app.exs:

      8 | Some other text
      └─ lib/my_app_web/controllers/page_controller.ex:

      12 | More text, same file
      └─ lib/my_app_web/controllers/page_controller.ex:
      """

      {:ok, result} = parse_output(:my_rule, output)

      assert result == %RuleResult{
               rule: :my_rule,
               changes: [],
               warnings: [
                 "config/my_app.exs",
                 "lib/my_app_web/controllers/page_controller.ex"
               ]
             }
    end
  end
end
