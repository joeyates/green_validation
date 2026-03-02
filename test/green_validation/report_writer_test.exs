defmodule GreenValidation.ReportWriterTest do
  use ExUnit.Case, async: true

  alias GreenValidation.{ReportWriter, Result, RuleResult, TestRun}

  @tmp_dir "/tmp/green_validation_test"

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)

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

  describe "write_json/2" do
    test "writes JSON file successfully", %{clean_result: result} do
      filepath = Path.join(@tmp_dir, "test_result.json")

      assert {:ok, ^filepath} = ReportWriter.write_json(result, filepath)
      assert File.exists?(filepath)

      {:ok, content} = File.read(filepath)
      {:ok, parsed} = Jason.decode(content)

      assert parsed["test_run"]["project_name"] == "test_project"
      assert parsed["baseline"] == "clean"
      # Empty rules are filtered out in JSON
      assert length(parsed["rules"]) == 0
    end

    test "creates valid JSON structure", %{result_with_changes: result} do
      filepath = Path.join(@tmp_dir, "test_result_changes.json")

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
    test "writes text file successfully", %{clean_result: result} do
      filepath = Path.join(@tmp_dir, "test_result.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)
      assert File.exists?(filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "VALIDATION REPORT"
      assert content =~ "Project: test_project"
      assert content =~ "test_rule_1"
      assert content =~ "test_rule_2"
    end

    test "formats baseline status correctly", %{result_with_changes: result} do
      filepath = Path.join(@tmp_dir, "test_baseline.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "Baseline Status: 🔧 Created formatting commit"
    end

    test "includes changes and warnings in output", %{result_with_changes: result} do
      filepath = Path.join(@tmp_dir, "test_details.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "lib/file1.ex"
      assert content =~ "lib/file2.ex"
      assert content =~ "test/file1_test.exs"
      assert content =~ "Changes needed for 2 files"
      assert content =~ "Warnings for 1 files"
    end

    test "includes summary statistics", %{result_with_changes: result} do
      filepath = Path.join(@tmp_dir, "test_summary.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "SUMMARY"
      assert content =~ "Total Rules Tested: 3"
      assert content =~ "Rules with Changes: 1"
      assert content =~ "Rules with Warnings: 1"
      assert content =~ "Rules with No Issues: 1"
    end

    test "formats clean results", %{clean_result: result} do
      filepath = Path.join(@tmp_dir, "test_clean.txt")

      assert {:ok, ^filepath} = ReportWriter.write_text(result, filepath)

      {:ok, content} = File.read(filepath)
      assert content =~ "✅ No issues found"
      assert content =~ "Rules with No Issues: 2"
    end
  end

  describe "write/3" do
    test "writes JSON format with auto-generated filename", %{clean_result: result} do
      assert {:ok, filepath} = ReportWriter.write(result, :json, output_dir: @tmp_dir)
      assert File.exists?(filepath)
      assert String.ends_with?(filepath, ".json")
      assert filepath =~ "validation_test_project_"
    end

    test "writes text format with auto-generated filename", %{clean_result: result} do
      assert {:ok, filepath} = ReportWriter.write(result, :text, output_dir: @tmp_dir)
      assert File.exists?(filepath)
      assert String.ends_with?(filepath, ".txt")
      assert filepath =~ "validation_test_project_"
    end

    test "uses custom filename when provided", %{clean_result: result} do
      custom_name = "my_custom_report.json"

      assert {:ok, filepath} =
               ReportWriter.write(result, :json, output_dir: @tmp_dir, filename: custom_name)

      assert String.ends_with?(filepath, custom_name)
    end

    test "creates output directory if it doesn't exist", %{clean_result: result} do
      nested_dir = Path.join(@tmp_dir, "nested/deep/path")
      refute File.exists?(nested_dir)

      assert {:ok, filepath} = ReportWriter.write(result, :json, output_dir: nested_dir)
      assert File.exists?(filepath)
      assert File.exists?(nested_dir)
    end
  end
end
