defmodule GreenValidation.CLI.ComparisonPdfTest do
  use ExUnit.Case, async: true

  alias GreenValidation.CLI.ComparisonPdf

  setup context do
    if tmp_dir = context[:tmp_dir] do
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
    end

    :ok
  end

  @comparison %{
    "generated_with" => %{"elixir_version" => "1.19.5"},
    "sources" => [
      %{"id" => "mix_format", "name" => "mix format", "repo_url" => "https://example.com/mf"}
    ],
    "rules" => [
      %{
        "id" => "spaces_around_binary_operators",
        "title" => "Spaces around binary operators",
        "category" => "formatting",
        "example" => %{"bad" => "1+1", "good" => "1 + 1"},
        "proposed_by" => ["mix_format"],
        "sources" => %{"mix_format" => %{"proposed" => true, "reference" => "formatter.ex"}}
      }
    ],
    "rules_with_no_source" => []
  }

  describe "main/1" do
    @tag :tmp_dir
    test "renders a comparison file to a PDF", %{tmp_dir: tmp_dir} do
      input = Path.join(tmp_dir, "comparison.json")
      File.write!(input, Jason.encode!(@comparison))
      out = Path.join([tmp_dir, "out", "comparison.pdf"])

      assert {:ok, ^out} = ComparisonPdf.main(["--input-path", input, "--output-path", out])
      assert File.exists?(out)
      assert out |> File.read!() |> String.starts_with?("%PDF-")
    end
  end
end
