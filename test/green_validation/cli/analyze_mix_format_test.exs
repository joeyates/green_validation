defmodule GreenValidation.CLI.AnalyzeMixFormatTest do
  use ExUnit.Case, async: true

  alias GreenValidation.CLI.AnalyzeMixFormat

  setup context do
    if tmp_dir = context[:tmp_dir] do
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
    end

    :ok
  end

  describe "main/1" do
    @tag :tmp_dir
    test "writes a valid mix_format source artifact", %{tmp_dir: tmp_dir} do
      path = Path.join([tmp_dir, "sources", "mix_format.json"])

      assert {:ok, ^path} = AnalyzeMixFormat.main(["--output-path", path])
      assert File.exists?(path)

      data = path |> File.read!() |> Jason.decode!()

      assert data["source"]["id"] == "mix_format"
      assert is_list(data["rules"])
      assert length(data["rules"]) > 0
      assert Map.has_key?(data, "unmapped")
    end
  end
end
