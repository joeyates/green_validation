defmodule GreenValidation.OutputParserTest do
  use ExUnit.Case, async: true

  import GreenValidation.OutputParser

  alias GreenValidation.{Repo, RuleResult}

  describe "parse_output/3" do
    test "extracts file paths from warnings" do
      repo = %Repo{name: "test_project", repo: "https://example.com/test_project.git"}

      output = """
      5 | Some text
      └─ config/my_app.exs:

      8 | Some other text
      └─ lib/my_app_web/controllers/page_controller.ex:

      12 | More text, same file
      └─ lib/my_app_web/controllers/page_controller.ex:
      """

      {:ok, result} = parse_output(repo, :my_rule, output)

      assert result == %RuleResult{
               rule: :my_rule,
               changes: [],
               warnings: [
                 "config/my_app.exs",
                 "lib/my_app_web/controllers/page_controller.ex"
               ]
             }
    end

    test "extracts file paths from changes with ANSI color codes" do
      repo = %Repo{name: "test_project", repo: "https://example.com/test_project.git"}

      root_path = [__DIR__, "..", ".."] |> Path.join() |> Path.expand()

      output = """
      \e[1m\e[31m#{root_path}/repos/test_project/lib/my_app_web/controllers/page_controller.ex\e[0m
      \e[1m\e[31m#{root_path}/repos/test_project/lib/my_app_web/views/page_view.ex\e[0m
      """

      {:ok, result} = parse_output(repo, :my_rule, output)

      assert result == %RuleResult{
               rule: :my_rule,
               changes: [
                 "lib/my_app_web/controllers/page_controller.ex",
                 "lib/my_app_web/views/page_view.ex"
               ],
               warnings: []
             }
    end
  end
end
