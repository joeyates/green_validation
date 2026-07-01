defmodule GreenValidation.CLI.AnalyzeLexmagTest do
  use ExUnit.Case, async: true

  alias GreenValidation.CLI.AnalyzeGuide
  alias GreenValidation.Sources.Lexmag

  setup context do
    if tmp_dir = context[:tmp_dir] do
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
    end

    :ok
  end

  describe "main/3 for lexmag" do
    @tag :tmp_dir
    test "writes a valid lexmag artifact from a vendored guide", %{tmp_dir: tmp_dir} do
      # A minimal vendored guide containing exactly the mapped anchors.
      markdown =
        Lexmag.mapping()
        |> Enum.map(fn {_id, anchor} -> ~s(<a name="#{anchor}"></a>\n) end)
        |> Enum.join("\n")

      tmp_dir |> Path.join("lexmag.md") |> File.write!(markdown)

      out = Path.join([tmp_dir, "sources", "lexmag.json"])

      assert {:ok, ^out} =
               AnalyzeGuide.main(
                 ["--guides-path", tmp_dir, "--output-path", out],
                 :lexmag,
                 Lexmag.mapping()
               )

      data = out |> File.read!() |> Jason.decode!()

      assert data["source"]["id"] == "lexmag"
      assert length(data["rules"]) == length(Lexmag.mapping())
      assert Enum.all?(data["rules"], & &1["proposed"])
    end
  end
end
