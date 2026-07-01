defmodule GreenValidation.CLI.CompareStylesTest do
  use ExUnit.Case, async: true

  alias GreenValidation.CLI.CompareStyles
  alias GreenValidation.StyleCatalog

  setup context do
    if tmp_dir = context[:tmp_dir] do
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
    end

    :ok
  end

  describe "main/1" do
    @tag :tmp_dir
    test "joins per-source artifacts into a comparison", %{tmp_dir: tmp_dir} do
      write_artifact(tmp_dir, "mix_format", [
        %{id: "spaces_around_binary_operators", proposed: true, reference: "formatter.ex"}
      ])

      write_artifact(tmp_dir, "lexmag", [
        %{id: "snake_case_atoms_and_variables", proposed: true, reference: "https://lexmag#snake"}
      ])

      out = Path.join([tmp_dir, "comparison.json"])

      assert {:ok, ^out} =
               CompareStyles.main(["--sources-path", tmp_dir, "--output-path", out])

      data = out |> File.read!() |> Jason.decode!()

      assert length(data["rules"]) == length(StyleCatalog.all())
      assert length(data["sources"]) == 4

      spaces = Enum.find(data["rules"], &(&1["id"] == "spaces_around_binary_operators"))
      assert spaces["sources"]["mix_format"]["proposed"] == true
    end
  end

  defp write_artifact(dir, id, rules) do
    body = Jason.encode_to_iodata!(%{source: %{id: id}, rules: rules, unmapped: []}, pretty: true)
    dir |> Path.join("#{id}.json") |> File.write!(body)
  end
end
