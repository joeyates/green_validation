defmodule GreenValidation.RulesTest do
  use ExUnit.Case

  alias GreenValidation.{Project, Rules}

  describe "all_enabled/1" do
    test "returns every rule with `enabled: true`" do
      project = %Project{name: "example", url: "https://example.com/repo"}

      enabled = Rules.all_enabled(project)

      assert Keyword.keys(enabled) == Rules.all()
      assert Enum.all?(enabled, fn {_rule, config} -> config == [enabled: true] end)
    end

    test "merges in project-specific rule setup" do
      project = %Project{
        name: "example",
        url: "https://example.com/repo",
        rule_config: [
          avoid_needless_pipelines: [except: ["lib/foo.ex"]]
        ]
      }

      enabled = Rules.all_enabled(project)

      assert enabled[:avoid_needless_pipelines] == [enabled: true, except: ["lib/foo.ex"]]
      assert enabled[:no_nil_else] == [enabled: true]
    end
  end
end
