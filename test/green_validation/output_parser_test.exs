defmodule GreenValidation.OutputParserTest do
  use ExUnit.Case, async: true

  import GreenValidation.OutputParser

  alias GreenValidation.{Change, Project, RuleResult, Warning}

  describe "parse_output/3" do
    test "extracts warnings" do
      project = %Project{name: "test_project", url: "https://example.com/test_project.git"}

      output = """
      warning: some warning
      5 | some_code()
      └─ config/my_app.exs: (file)

      warning: another warning
      8 | other_code()
      └─ lib/my_app_web/controllers/page_controller.ex: (file)
      """

      {:ok, result} = parse_output(project, :my_rule, output)

      assert result == %RuleResult{
               rule: :my_rule,
               changes: [],
               warnings: [
                 %Warning{
                   message: "some warning",
                   line: 5,
                   code: "some_code()",
                   file: "config/my_app.exs"
                 },
                 %Warning{
                   message: "another warning",
                   line: 8,
                   code: "other_code()",
                   file: "lib/my_app_web/controllers/page_controller.ex"
                 }
               ]
             }
    end

    test "extracts changes with ANSI color codes" do
      project = %Project{name: "test_project", url: "https://example.com/test_project.git"}

      root_path = [__DIR__, "..", ".."] |> Path.join() |> Path.expand()

      output = """
      \e[1m\e[31m#{root_path}/repos/test_project/lib/my_app_web/controllers/page_controller.ex
      \e[0m
      diff one
      \e[1m\e[31m#{root_path}/repos/test_project/lib/my_app_web/views/page_view.ex
      \e[0m
      diff two
      """

      {:ok, result} = parse_output(project, :my_rule, output)

      assert result == %RuleResult{
               rule: :my_rule,
               changes: [
                 %Change{
                   path: "lib/my_app_web/controllers/page_controller.ex",
                   diff: "diff one\n"
                 },
                 %Change{
                   path: "lib/my_app_web/views/page_view.ex",
                   diff: "diff two\n"
                 }
               ],
               warnings: []
             }
    end
  end
end
