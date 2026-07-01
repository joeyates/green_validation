defmodule GreenValidation.CLI.AnalyzeChristopherAdamsTest do
  use ExUnit.Case, async: true

  alias GreenValidation.CLI.AnalyzeGuide
  alias GreenValidation.Sources.ChristopherAdams

  setup context do
    if tmp_dir = context[:tmp_dir] do
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
    end

    :ok
  end

  describe "main/3 for christopher_adams" do
    @tag :tmp_dir
    test "writes a valid artifact from a vendored guide", %{tmp_dir: tmp_dir} do
      markdown =
        ChristopherAdams.mapping()
        |> Enum.map(fn {_id, anchor} -> ~s(<a name="#{anchor}"></a>\n) end)
        |> Enum.join("\n")

      tmp_dir |> Path.join("christopher_adams.md") |> File.write!(markdown)

      out = Path.join([tmp_dir, "sources", "christopher_adams.json"])

      assert {:ok, ^out} =
               AnalyzeGuide.main(
                 ["--guides-path", tmp_dir, "--output-path", out],
                 :christopher_adams,
                 ChristopherAdams.mapping()
               )

      data = out |> File.read!() |> Jason.decode!()

      assert data["source"]["id"] == "christopher_adams"
      assert length(data["rules"]) == length(ChristopherAdams.mapping())
      assert Enum.all?(data["rules"], & &1["proposed"])
    end
  end
end
