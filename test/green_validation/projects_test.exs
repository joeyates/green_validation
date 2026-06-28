defmodule GreenValidation.ProjectsTest do
  use ExUnit.Case

  alias GreenValidation.Projects

  describe "load/1 for the nerves project" do
    test "configures a post-checkout callback that installs nerves_bootstrap" do
      {:ok, project} = Projects.load("nerves")

      assert project.post_checkout == {Projects, :nerves_post_checkout}
    end
  end
end
