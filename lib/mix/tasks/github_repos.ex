defmodule Mix.Tasks.GreenValidation.GithubRepos do
  @moduledoc """
  Downloads a list of popular GitHub repositories.
  """
  use Mix.Task

  alias GreenValidation.CLI.GithubRepos

  @shortdoc "Download a list of popular GitHub repositories"
  def run(args) do
    Mix.Task.run("app.start")
    GithubRepos.main(args)
  end
end
