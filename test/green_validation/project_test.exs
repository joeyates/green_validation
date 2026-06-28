defmodule GreenValidation.ProjectTest do
  use ExUnit.Case

  alias GreenValidation.{Project, Subproject}

  describe "report_names/1" do
    test "returns the project name for a project without subprojects" do
      project = %Project{name: "phoenix", url: "https://example.com/phoenix.git"}

      assert Project.report_names(project) == ["phoenix"]
    end

    test "returns a qualified name per subproject when the project has subprojects" do
      project = %Project{
        name: "electric",
        url: "https://example.com/electric.git",
        subprojects: [
          %Subproject{path: "packages/electric-telemetry"},
          %Subproject{path: "packages/elixir-client"}
        ]
      }

      assert Project.report_names(project) == [
               "electric (packages/electric-telemetry)",
               "electric (packages/elixir-client)"
             ]
    end
  end

  describe "has_formatter_exs?/1 and has_tool_versions?/1" do
    @describetag :tmp_dir

    setup %{tmp_dir: tmp_dir} do
      previous = Application.get_env(:green_validation, :repos_dir)
      Application.put_env(:green_validation, :repos_dir, Path.dirname(tmp_dir))
      on_exit(fn -> Application.put_env(:green_validation, :repos_dir, previous) end)

      name = Path.basename(tmp_dir)

      {:ok, project: %Project{name: name, url: "https://example.com/x.git"}, path: tmp_dir}
    end

    test "has_formatter_exs?/1 reflects whether a .formatter.exs exists", %{
      project: project,
      path: path
    } do
      refute Project.has_formatter_exs?(project)

      path |> Path.join(".formatter.exs") |> File.write!("[]\n")

      assert Project.has_formatter_exs?(project)
    end

    test "has_tool_versions?/1 reflects whether a .tool-versions exists", %{
      project: project,
      path: path
    } do
      refute Project.has_tool_versions?(project)

      path |> Path.join(".tool-versions") |> File.write!("elixir 1.17.0\n")

      assert Project.has_tool_versions?(project)
    end
  end

  describe "clone/1 with an existing repository" do
    @describetag :tmp_dir

    setup %{tmp_dir: tmp_dir} do
      previous = Application.get_env(:green_validation, :repos_dir)
      Application.put_env(:green_validation, :repos_dir, Path.join(tmp_dir, "repos"))
      on_exit(fn -> Application.put_env(:green_validation, :repos_dir, previous) end)

      upstream = Path.join(tmp_dir, "upstream")
      name = "project_test_repo_#{System.unique_integer([:positive])}"

      File.mkdir_p!(upstream)

      git!(["init", "-b", "main"], upstream)
      git!(["config", "user.email", "test@example.com"], upstream)
      git!(["config", "user.name", "Test"], upstream)
      upstream |> Path.join("README.md") |> File.write!("one\n")
      git!(["add", "."], upstream)
      git!(["commit", "-m", "first"], upstream)

      {:ok, upstream: upstream, name: name}
    end

    test "advances HEAD to the latest upstream commit", %{upstream: upstream, name: name} do
      project = %Project{name: name, url: upstream}

      {:ok, first} = Project.clone(project)

      upstream |> Path.join("README.md") |> File.write!("two\n")
      git!(["add", "."], upstream)
      git!(["commit", "-m", "second"], upstream)

      {:ok, second} = Project.clone(project)

      refute second.commit_sha == first.commit_sha
      assert second.commit_sha == upstream_head(upstream)
    end
  end

  describe "compile/1" do
    test "skips compilation when the project is configured not to compile" do
      project = %Project{name: "elixir", url: "https://example.com/elixir.git", compile: false}

      assert Project.compile(project) == :ok
    end
  end

  defp upstream_head(upstream) do
    {sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: upstream)
    String.trim(sha)
  end

  defp git!(args, cd) do
    {_output, 0} = System.cmd("git", args, cd: cd, stderr_to_stdout: true)
    :ok
  end
end
