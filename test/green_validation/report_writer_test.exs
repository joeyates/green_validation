defmodule GreenValidation.ReportWriterTest do
  use ExUnit.Case, async: true

  alias GreenValidation.{Change, ReportWriter, Result, RuleResult, TestRun, Warning}

  setup do
    test_run = %TestRun{
      project_name: "test_project",
      repository: "https://github.com/test/project",
      commit_sha: "abc123def456",
      branch: "main",
      green_version: "0.1.0"
    }

    clean_result = %Result{
      test_run: test_run,
      baseline: :clean,
      rules: [
        %RuleResult{rule: :test_rule_1, changes: [], warnings: []},
        %RuleResult{rule: :test_rule_2, changes: [], warnings: []}
      ]
    }

    result_with_changes = %Result{
      test_run: test_run,
      baseline: :created_format_commit,
      rules: [
        %RuleResult{
          rule: :test_rule_1,
          changes: ["lib/file1.ex", "lib/file2.ex"],
          warnings: []
        },
        %RuleResult{
          rule: :test_rule_2,
          changes: [],
          warnings: ["test/file1_test.exs"]
        },
        %RuleResult{rule: :test_rule_3, changes: [], warnings: []}
      ]
    }

    {:ok, clean_result: clean_result, result_with_changes: result_with_changes}
  end

  setup context do
    if tmp_dir = context[:tmp_dir] do
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
    end

    :ok
  end

  describe "write_json/2" do
    @tag :tmp_dir
    test "writes JSON file successfully", %{clean_result: result, tmp_dir: tmp_dir} do
      filepath = Path.join(tmp_dir, "test_result.json")

      assert {:ok, ^filepath} = ReportWriter.write_json(result, filepath)
      assert File.exists?(filepath)

      {:ok, content} = File.read(filepath)
      {:ok, parsed} = Jason.decode(content)

      assert parsed["test_run"]["project_name"] == "test_project"
      assert parsed["baseline"] == "clean"
      # Empty rules are filtered out in JSON
      assert length(parsed["rules"]) == 0
    end

    @tag :tmp_dir
    test "creates valid JSON structure", %{result_with_changes: result, tmp_dir: tmp_dir} do
      filepath = Path.join(tmp_dir, "test_result_changes.json")

      assert {:ok, ^filepath} = ReportWriter.write_json(result, filepath)

      {:ok, content} = File.read(filepath)
      {:ok, parsed} = Jason.decode(content)

      assert parsed["test_run"]["repository"] == "https://github.com/test/project"
      assert parsed["baseline"] == "created_format_commit"
      # Only rules with changes or warnings are included (test_rule_3 is filtered out)
      assert length(parsed["rules"]) == 2

      rule1 = Enum.find(parsed["rules"], &(&1["rule"] == "test_rule_1"))
      assert length(rule1["changes"]) == 2
      assert "lib/file1.ex" in rule1["changes"]
    end

    @tag :tmp_dir
    test "serializes Change and Warning structs as file paths matching the schema", %{
      tmp_dir: tmp_dir
    } do
      test_run = %TestRun{
        project_name: "test_project",
        repository: "https://github.com/test/project",
        commit_sha: "abc123def456",
        branch: "main",
        green_version: "0.1.0"
      }

      result = %Result{
        test_run: test_run,
        baseline: :clean,
        rules: [
          %RuleResult{
            rule: :avoid_needless_pipelines,
            changes: [
              %Change{path: "lib/phoenix/endpoint.ex", diff: "-foo\n+bar"},
              %Change{path: "lib/phoenix/router.ex", diff: "-baz\n+qux"}
            ],
            warnings: [
              %Warning{
                code: "some_code()",
                file: "test/phoenix/endpoint_test.exs",
                line: 42,
                message: "a warning"
              }
            ]
          }
        ]
      }

      filepath = Path.join(tmp_dir, "test_structs.json")

      assert {:ok, ^filepath} = ReportWriter.write_json(result, filepath)

      {:ok, content} = File.read(filepath)
      {:ok, parsed} = Jason.decode(content)

      rule = Enum.find(parsed["rules"], &(&1["rule"] == "avoid_needless_pipelines"))

      assert rule["changes"] == ["lib/phoenix/endpoint.ex", "lib/phoenix/router.ex"]
      assert rule["warnings"] == ["test/phoenix/endpoint_test.exs"]
    end

    test "returns error for invalid filepath" do
      result = %Result{
        test_run: %TestRun{
          project_name: "test",
          repository: "repo",
          commit_sha: "sha",
          branch: "main",
          green_version: "0.1.0"
        },
        baseline: :clean,
        rules: []
      }

      invalid_path = "/nonexistent_directory/nowhere/test.json"
      assert {:error, _reason} = ReportWriter.write_json(result, invalid_path)
    end
  end

  describe "write_text/2" do
    @tag :tmp_dir
    test "writes text file successfully", %{clean_result: result, tmp_dir: tmp_dir} do
      filepath = Path.join(tmp_dir, "test_result.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)
      assert File.exists?(filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "VALIDATION REPORT"
      assert content =~ "Project: test_project"
      assert content =~ "test_rule_1"
      assert content =~ "test_rule_2"
    end

    @tag :tmp_dir
    test "formats baseline status correctly", %{result_with_changes: result, tmp_dir: tmp_dir} do
      filepath = Path.join(tmp_dir, "test_baseline.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "Baseline Status: 🔧 Created formatting commit"
    end

    @tag :tmp_dir
    test "includes changes and warnings in output", %{
      result_with_changes: result,
      tmp_dir: tmp_dir
    } do
      filepath = Path.join(tmp_dir, "test_details.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "lib/file1.ex"
      assert content =~ "lib/file2.ex"
      assert content =~ "test/file1_test.exs"
      assert content =~ "Changes needed for 2 files"
      assert content =~ "Warnings for 1 files"
    end

    @tag :tmp_dir
    test "includes summary statistics", %{result_with_changes: result, tmp_dir: tmp_dir} do
      filepath = Path.join(tmp_dir, "test_summary.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "SUMMARY"
      assert content =~ "Total Rules Tested: 3"
      assert content =~ "Rules with Changes: 1"
      assert content =~ "Rules with Warnings: 1"
      assert content =~ "Rules with No Issues: 1"
    end

    @tag :tmp_dir
    test "formats clean results", %{clean_result: result, tmp_dir: tmp_dir} do
      filepath = Path.join(tmp_dir, "test_clean.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "✅ No issues found"
      assert content =~ "Rules with No Issues: 2"
    end
  end

  describe "filename/3" do
    test "builds the JSON filename from project name and short commit SHA" do
      assert ReportWriter.filename("phoenix", "abc123def456789", :json) ==
               "validation_phoenix_abc123de.json"
    end

    test "builds the text filename" do
      assert ReportWriter.filename("phoenix", "abc123def456789", :text) ==
               "validation_phoenix_abc123de.txt"
    end

    test "replaces spaces in the project name" do
      assert ReportWriter.filename("my project", "abc123def456789", :json) ==
               "validation_my_project_abc123de.json"
    end
  end

  describe "report_exists?/4" do
    @tag :tmp_dir
    test "is true when a matching report already exists in the output dir", %{tmp_dir: tmp_dir} do
      filename = ReportWriter.filename("phoenix", "abc123def456789", :json)
      tmp_dir |> Path.join(filename) |> File.write!("{}")

      assert ReportWriter.report_exists?("phoenix", "abc123def456789", :json,
               output_dir: tmp_dir
             )
    end

    @tag :tmp_dir
    test "is false when no matching report exists", %{tmp_dir: tmp_dir} do
      refute ReportWriter.report_exists?("phoenix", "abc123def456789", :json,
               output_dir: tmp_dir
             )
    end

    @tag :tmp_dir
    test "matches only the same commit SHA", %{tmp_dir: tmp_dir} do
      filename = ReportWriter.filename("phoenix", "abc123def456789", :json)
      tmp_dir |> Path.join(filename) |> File.write!("{}")

      refute ReportWriter.report_exists?("phoenix", "999999999999", :json, output_dir: tmp_dir)
    end
  end

  describe "write/3" do
    @tag :tmp_dir
    test "writes JSON format with auto-generated filename", %{
      clean_result: result,
      tmp_dir: tmp_dir
    } do
      assert {:ok, filepath} = ReportWriter.write(result, :json, output_dir: tmp_dir)
      assert File.exists?(filepath)
      assert String.ends_with?(filepath, ".json")
      # Filename should contain project name and first 8 chars of commit SHA
      assert filepath =~ "validation_test_project_abc123de.json"
    end

    @tag :tmp_dir
    test "writes text format with auto-generated filename", %{
      clean_result: result,
      tmp_dir: tmp_dir
    } do
      assert {:ok, filepath} = ReportWriter.write(result, :text, output_dir: tmp_dir)
      assert File.exists?(filepath)
      assert String.ends_with?(filepath, ".txt")
      # Filename should contain project name and first 8 chars of commit SHA
      assert filepath =~ "validation_test_project_abc123de.txt"
    end

    @tag :tmp_dir
    test "uses custom filename when provided", %{clean_result: result, tmp_dir: tmp_dir} do
      custom_name = "my_custom_report.json"

      assert {:ok, filepath} =
               ReportWriter.write(result, :json, output_dir: tmp_dir, filename: custom_name)

      assert String.ends_with?(filepath, custom_name)
    end

    @tag :tmp_dir
    test "creates output directory if it doesn't exist", %{clean_result: result, tmp_dir: tmp_dir} do
      nested_dir = Path.join(tmp_dir, "nested/deep/path")
      refute File.exists?(nested_dir)

      assert {:ok, filepath} = ReportWriter.write(result, :json, output_dir: nested_dir)
      assert File.exists?(filepath)
      assert File.exists?(nested_dir)
    end
  end
end
