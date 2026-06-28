defmodule GreenValidation.CLI.DumpMasterRulesTest do
  use ExUnit.Case, async: true

  alias GreenValidation.CLI.DumpMasterRules
  alias GreenValidation.StyleCatalog

  setup context do
    if tmp_dir = context[:tmp_dir] do
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
    end

    :ok
  end

  describe "main/1" do
    @tag :tmp_dir
    test "writes the master rules as JSON to the given path", %{tmp_dir: tmp_dir} do
      path = Path.join([tmp_dir, "nested", "master_rules.json"])

      assert {:ok, ^path} = DumpMasterRules.main(["--output-path", path])
      assert File.exists?(path)

      rules = path |> File.read!() |> Jason.decode!()

      assert length(rules) == length(StyleCatalog.all())

      first = hd(rules)
      assert Map.has_key?(first, "id")
      assert Map.has_key?(first, "title")
      assert Map.has_key?(first, "category")
    end
  end
end
