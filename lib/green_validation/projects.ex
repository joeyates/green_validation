defmodule GreenValidation.Projects do
  @moduledoc """
  The projects handled by the validation suite. This module defines the list of projects to validate and provides helper functions to access their paths and metadata.
  """

  alias GreenValidation.Project

  @projects [
    %Project{
      name: "elixir",
      repo_name: "elixir",
      has_mix_exs: false,
      environment: {__MODULE__, :elixir_environment},
      rule_config: [
        avoid_needless_pipelines: [
          except: [
            {"lib/elixir/test/elixir/code_normalizer/quoted_ast_test.exs", [471, 472, 636]}
          ]
        ],
        true_in_cond: [
          except: [
            "lib/elixir/test/elixir/kernel/expansion_test.exs",
            {"lib/elixir/test/elixir/kernel/guard_test.exs", 421},
            {"lib/elixir/lib/macro.ex", 2813},
            "lib/elixir/test/elixir/module/types/expr_test.exs",
            "lib/elixir/test/elixir/module/types/helpers_test.exs",
            "lib/elixir/test/elixir/kernel/special_forms_test.exs",
            "lib/elixir/test/elixir/fixtures/dialyzer/cond.ex"
          ]
        ],
        upper_camel_case_for_modules: [
          except: [
            "lib/mix/test/mix/tasks/compile.erlang_test.exs",
            "lib/iex/test/iex/autocomplete_test.exs",
            {"lib/elixir/test/elixir/map_test.exs", 493},
            {"lib/elixir/test/elixir/kernel_test.exs", [913, 917]},
            {"lib/elixir/test/elixir/module_test.exs", [277, 285]}
          ]
        ],
        avoid_caps: [
          except: [
            "lib/elixir/test/elixir/kernel/expansion_test.exs",
            "lib/elixir/test/elixir/kernel/alias_test.exs",
            {"lib/iex/test/iex/helpers_test.exs", 1561},
            "lib/elixir/test/elixir/code_normalizer/quoted_ast_test.exs",
            "lib/iex/test/iex/autocomplete_test.exs",
            "lib/elixir/test/elixir/kernel/string_tokenizer_test.exs",
            "lib/elixir/test/elixir/kernel/sigils_test.exs",
            {"lib/iex/lib/iex/pry.ex", 576},
            "lib/elixir/lib/kernel.ex",
            "lib/elixir/lib/string.ex",
            "lib/elixir/test/elixir/kernel/expansion_test.exs",
            "lib/elixir/test/elixir/inspect_test.exs",
            "lib/elixir/unicode/unicode.ex",
            "lib/elixir/test/elixir/kernel/quote_test.exs"
          ]
        ]
      ]
    },
    %Project{
      name: "phoenix",
      repo_name: "phoenix"
    },
    %Project{
      name: "phoenix_live_view",
      repo_name: "phoenix_live_view"
    },
    %Project{
      name: "hexpm",
      repo_name: "hexpm"
    },
    %Project{
      name: "nerves",
      repo_name: "nerves"
    },
    %Project{
      name: "absinthe",
      repo_name: "absinthe"
    },
    %Project{
      name: "broadway",
      repo_name: "broadway"
    },
    %Project{
      name: "credo",
      repo_name: "credo"
    }
  ]

  @spec all() :: list(Project.t())
  def all(), do: @projects

  @spec find_by_name(String.t()) :: {:ok, Project.t()} | {:error, String.t()}
  def find_by_name(project_name) do
    case Enum.find(all(), &(&1.name == project_name)) do
      nil -> {:error, "Project not found: #{project_name}"}
      project -> {:ok, project}
    end
  end

  def elixir_environment(%Project{} = project) do
    # For Elixir, we want to ensure that the PATH includes the local elixir bin directory
    path = Project.path(project)
    [{"PATH", "#{path}/bin:#{System.get_env("PATH")}"}]
  end
end
