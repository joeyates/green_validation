defmodule GreenValidation.Installer.MixExsTest do
  use ExUnit.Case, async: true

  import GreenValidation.Installer.MixExs

  describe "add_dependency/2" do
    test "adds dependency to content without deps block" do
      content = """
      defmodule MyProject.MixProject do
        use Mix.Project

        def project() do
          [
            app: :my_project,
            version: "0.1.0"
          ]
        end
      end
      """

      updated = add_dependency(content, {:green_formatter, "~> 0.1"})

      expected = """
        defp deps() do
          [
            {:green_formatter, \"~> 0.1\"}
          ]
        end
      """

      assert updated =~ expected
    end

    test "adds deps call" do
      content = """
      defmodule MyProject.MixProject do
        use Mix.Project

        def project() do
          [
            app: :my_project,
            version: "0.1.0"
          ]
        end
      end
      """

      updated = add_dependency(content, {:green_formatter, "~> 0.1"})

      expected = """
        def project() do
          [
            deps: deps(),
            app: :my_project,
            version: "0.1.0"
          ]
        end
      """

      assert updated =~ expected
    end

    test "adds dependency to content with existing deps block" do
      content = """
      defmodule MyProject.MixProject do
        use Mix.Project

        def project() do
          [
            app: :my_project,
            version: "0.1.0",
            deps: deps()
          ]
        end

        defp deps do
          [
            {:ex_unit, "~> 1.0"}
          ]
        end
      end
      """

      updated = add_dependency(content, {:green_formatter, "~> 0.1"})

      expected = """
          [
            {:ex_unit, \"~> 1.0\"},
            {:green_formatter, \"~> 0.1\"}
          ]
      """

      assert updated =~ expected
    end

    test "adds dependency to content with existing, empty deps block" do
      content = """
      defmodule MyProject.MixProject do
        use Mix.Project

        def project() do
          [
            app: :my_project,
            version: "0.1.0",
            deps: deps()
          ]
        end

        defp deps do
          []
        end
      end
      """

      updated = add_dependency(content, {:green_formatter, "~> 0.1"})

      expected = """
          [
            {:green_formatter, \"~> 0.1\"}
          ]
      """

      assert updated =~ expected
    end

    test "replaces existing dependency if already present" do
      content = """
      defmodule MyProject.MixProject do
        use Mix.Project

        def project() do
          [
            app: :my_project,
            version: "0.1.0",
            deps: deps()
          ]
        end

        defp deps do
          [
            {:green_formatter, "~> 0.0"}
          ]
        end
      end
      """

      updated = add_dependency(content, {:green_formatter, "~> 0.1"})

      expected = """
          [
            {:green_formatter, \"~> 0.1\"}
          ]
      """

      assert updated =~ expected
    end

    test "ensures the file ends with a newline" do
      content = """
      defmodule MyProject.MixProject do
        use Mix.Project

        def project() do
          [
            app: :my_project,
            version: "0.1.0"
          ]
        end
      end
      """

      updated = add_dependency(content, {:green_formatter, "~> 0.1"})

      assert String.ends_with?(updated, "end\n")
    end
  end
end
