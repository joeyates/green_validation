defmodule GreenValidation.ProjectTest do
  use ExUnit.Case

  alias GreenValidation.Project

  describe "clone/1 with an existing repository" do
    @describetag :tmp_dir

    setup %{tmp_dir: tmp_dir} do
      upstream = Path.join(tmp_dir, "upstream")
      name = "project_test_repo_#{System.unique_integer([:positive])}"
      clone_path = Path.join(Project.repos_dir(), name)

      File.mkdir_p!(upstream)

      on_exit(fn ->
        File.rm_rf!(clone_path)
        File.rm_rf!(tmp_dir)
      end)

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
