defmodule GreenValidation.Projects do
  @moduledoc """
  The projects handled by the validation suite.

  This module loads a generated list of projects, then applies overrides.
  It also provides helper functions to access their paths and metadata.
  """

  alias GreenValidation.{Project, Subproject}
  alias GreenValidation.Installer.{FormatterExs, MixExs}

  require Logger

  @all_projects_path "repos/merged.json"

  @projects %{
    "30-days-of-elixir" => %Project{
      name: "30-days-of-elixir",
      url: "https://github.com/seven1m/30-days-of-elixir",
      default_branch: "master",
      formatter_exs_setup: {__MODULE__, :thirty_days_of_elixir_formatter_exs_setup}
    },
    "anoma" => %Project{
      name: "anoma",
      url: "https://github.com/anoma/anoma",
      default_branch: "base",
      subprojects: [
        # 5 of the 6 packages have problems with compiling lib/google_protos/struct.pb.ex
        # %Subproject{path: "apps/anoma_client"},
        # %Subproject{path: "apps/anoma_lib"},
        # %Subproject{path: "apps/anoma_node"},
        # %Subproject{path: "apps/anoma_protobuf"},
        %Subproject{path: "apps/compile_protoc"}
        # %Subproject{path: "apps/event_broker"}
      ]
    },
    "awesome-elixir" => %Project{
      name: "awesome-elixir",
      url: "https://github.com/h4cc/awesome-elixir",
      default_branch: "master",
      formatter_exs_setup: {__MODULE__, :awesome_elixir_formatter_exs_setup}
    },
    "benchee" => %Project{
      name: "benchee",
      url: "https://github.com/bencheeorg/benchee",
      mix_exs_add_dependency: {__MODULE__, :benchee_mix_exs_add_dependency}
    },
    "desktop" => %Project{
      name: "desktop",
      url: "https://github.com/elixir-desktop/desktop",
      mix_exs_add_dependency: {__MODULE__, :desktop_mix_exs_add_dependency}
    },
    "distillery" => %Project{
      name: "distillery",
      url: "https://github.com/bitwalker/distillery",
      default_branch: "master",
      post_checkout: {__MODULE__, :distillery_post_checkout},
      mix_command: {__MODULE__, :run_asdf_mix}
    },
    "ecto" => %Project{
      name: "ecto",
      url: "https://github.com/elixir-ecto/ecto",
      default_branch: "master",
      formatter_exs_setup: {__MODULE__, :ecto_formatter_exs_setup}
    },
    "electric" => %Project{
      name: "electric",
      post_checkout: {__MODULE__, :electric_post_checkout},
      url: "https://github.com/electric-sql/electric",
      subprojects: [
        %Subproject{
          path: "packages/electric-telemetry",
          mix_exs_add_dependency: {__MODULE__, :electric_mix_exs_add_dependency}
        },
        %Subproject{
          path: "packages/elixir-client"
        },
        %Subproject{
          path: "packages/sync-service",
          mix_exs_add_dependency: {__MODULE__, :electric_mix_exs_add_dependency}
        }
      ]
    },
    "elixir" => %Project{
      name: "elixir",
      url: "https://github.com/elixir-lang/elixir",
      environment: {__MODULE__, :elixir_environment},
      post_checkout: {__MODULE__, :elixir_post_checkout},
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
    "elixir_style_guide" => %Project{
      name: "elixir_style_guide",
      url: "https://github.com/christopheradams/elixir_style_guide",
      default_branch: "master",
      formatter_exs_setup: {__MODULE__, :elixir_style_guide_formatter_exs_setup}
    },
    "expert" => %Project{
      name: "expert",
      url: "https://github.com/elixir-lang/expert",
      subprojects: [
        %Subproject{
          path: "apps/engine"
        },
        %Subproject{
          path: "apps/expert"
        },
        %Subproject{
          path: "apps/expert_credo"
        },
        %Subproject{
          path: "apps/forge"
        }
      ]
    },
    "firezone" => %Project{
      name: "firezone",
      url: "https://github.com/firezone/firezone",
      path: "elixir"
    },
    "grpc" => %Project{
      name: "grpc",
      url: "https://github.com/elixir-grpc/grpc",
      default_branch: "master",
      subprojects: [
        %Subproject{
          path: "grpc_core"
        },
        %Subproject{
          path: "grpc_server"
        },
        %Subproject{
          path: "grpc_client"
        }
      ]
    },
    "jason" => %Project{
      name: "jason",
      url: "https://github.com/michalmuskala/jason",
      default_branch: "master",
      formatter_exs_setup: {__MODULE__, :jason_formatter_exs_setup}
    },
    "learn-elixir" => %Project{
      name: "learn-elixir",
      url: "https://github.com/dwyl/learn-elixir",
      post_checkout: {__MODULE__, :learn_elixir_post_checkout},
      subprojects: [
        %Subproject{
          path: "codecov_example"
        },
        %Subproject{
          path: "examples"
        }
      ]
    },
    "nx" => %Project{
      name: "nx",
      url: "https://github.com/elixir-nx/nx",
      subprojects: [
        %Subproject{
          path: "exla"
        },
        %Subproject{
          path: "nx"
        },
        %Subproject{
          path: "torchx"
        }
      ]
    },
    "phoenix" => %Project{
      name: "phoenix",
      url: "https://github.com/phoenixframework/phoenix",
      formatter_exs_setup: {__MODULE__, :phoenix_formatter_exs_setup}
    },
    "semaphore" => %Project{
      name: "semaphore",
      url: "https://github.com/semaphoreio/semaphore",
      subprojects: [
        %Subproject{
          path: "auth"
        }
      ]
    },
    "symphony" => %Project{
      name: "symphony",
      url: "https://github.com/openai/symphony",
      path: "elixir"
    }
  }

  @spec load(String.t()) :: {:ok, Project.t()} | {:error, String.t()}
  def load(project_name) do
    case @projects[project_name] do
      nil ->
        load_from_file(project_name)

      project ->
        {:ok, project}
    end
  end

  @spec load!(String.t()) :: Project.t() | no_return()
  def load!(project_name) do
    case load(project_name) do
      {:error, _reason} ->
        raise "Project not found: #{project_name}"

      {:ok, project} ->
        project
    end
  end

  @spec all() :: [Project.t()]
  def all() do
    @all_projects_path
    |> File.read!()
    |> Jason.decode!(keys: :atoms)
    |> Enum.map(fn data ->
      if Map.has_key?(@projects, data.name) do
        @projects[data.name]
      else
        struct!(Project, data)
      end
    end)
  end

  @spec load_from_file(String.t()) :: {:ok, Project.t()} | {:error, String.t()}
  def load_from_file(project_name) do
    case Enum.find(all(), &(&1.name == project_name)) do
      nil ->
        {:error, "Project not found: #{project_name}"}

      project ->
        {:ok, project}
    end
  end

  def thirty_days_of_elixir_formatter_exs_setup(%Project{} = project) do
    inputs = [
      inputs: ["*.exs"]
    ]

    FormatterExs.create_project_formatter(project, inputs)
  end

  def awesome_elixir_formatter_exs_setup(%Project{} = project) do
    inputs = [
      inputs: ["test/**/*.{ex,exs}"]
    ]

    FormatterExs.create_project_formatter(project, inputs)
  end

  def distillery_post_checkout(%Project{} = project) do
    Logger.info(
      "Running post-checkout step, to use an older Elixir, for Distillery repository..."
    )

    path = Project.path(project)
    tool_versions_path = Path.join(path, ".tool-versions")
    File.write!(tool_versions_path, "elixir 1.17.0\n")

    with {_output, 0} <- System.shell("git add .tool-versions", cd: path, stderr_to_stdout: true),
         {_output, 0} <-
           System.shell(~s(git commit -m "Add .tool-versions with Elixir 1.17.0"),
             cd: path,
             stderr_to_stdout: true
           ),
         {_output, 0} <- System.shell("asdf install", cd: path, stderr_to_stdout: true) do
      :ok
    else
      {output, _} ->
        Logger.error("Failed to run post-checkout step for Distillery: #{output}")
        {:error, "Failed to run post-checkout step for Distillery: #{output}"}
    end
  end

  def ecto_formatter_exs_setup(%Project{} = project) do
    inputs = [
      inputs: ["{mix,.formatter}.exs", "{lib,test}/**/*.{ex,exs}"]
    ]

    FormatterExs.update_project_formatter(project, inputs)
  end

  def electric_post_checkout(%Project{} = project) do
    run_asdf_install(project)
    run_mix_local_hex(project)
  end

  def benchee_mix_exs_add_dependency(%Project{} = project, dependency) do
    Logger.info("Adding Green dependency to Benchee's #{project.path}/mix.exs...")

    mix_path = Project.mix_exs_path(project)
    content = File.read!(mix_path)

    regex = ~r/
      (
        defp\sdeps\sdo\s*
        deps\s=\s\[
      )
    /sx
    dep_string = inspect(dependency)

    updated_content =
      regex
      |> Regex.replace(
        content,
        fn _match, def_start ->
          """
          #{def_start}
            #{dep_string},
          """
        end
      )
      |> MixExs.reformat()

    File.write!(mix_path, updated_content)

    :updated
  end

  def desktop_mix_exs_add_dependency(%Project{} = project, dependency) do
    Logger.info("Adding Green dependency to Desktop's #{project.path}/mix.exs...")

    mix_path = Project.mix_exs_path(project)
    content = File.read!(mix_path)

    regex = ~r/
      (
        defp\sdeps\(\)\sdo\s*
        desktop\s=\s\[
      )
    /sx
    dep_string = inspect(dependency)

    updated_content =
      regex
      |> Regex.replace(
        content,
        fn _match, def_start ->
          """
          #{def_start}
              #{dep_string},
          """
        end
      )
      |> MixExs.reformat()

    File.write!(mix_path, updated_content)

    :updated
  end

  def electric_mix_exs_add_dependency(%Project{} = project, dependency) do
    Logger.info("Adding Green dependency to Electric's #{project.path}/mix.exs...")

    mix_path =
      project
      |> Project.path()
      |> Path.join("mix.exs")

    content = File.read!(mix_path)

    regex = ~r/
      (
        defp\sdeps\sdo\s*
        List.flatten\([\[\s]*
      )
    /sx
    dep_string = inspect(dependency)

    updated_content =
      regex
      |> Regex.replace(
        content,
        fn _match, def_start ->
          """
          #{def_start}
              #{dep_string},
          """
        end
      )
      |> MixExs.reformat()

    File.write!(mix_path, updated_content)

    :updated
  end

  def elixir_environment(%Project{} = project) do
    # For Elixir, we want to ensure that the PATH includes the local elixir bin directory
    path = Project.path(project)
    [{"PATH", "#{path}/bin:#{System.get_env("PATH")}"}]
  end

  def elixir_post_checkout(%Project{} = project) do
    Logger.info("Running post-checkout step, 'make', for Elixir repository...")
    path = Project.path(project)

    case System.cmd("make", [], cd: path, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _} ->
        {:error, "Failed to run post-checkout step for Elixir: #{output}"}
    end
  end

  def elixir_style_guide_formatter_exs_setup(%Project{} = project) do
    inputs = [
      inputs: ["mix.exs"]
    ]

    FormatterExs.create_project_formatter(project, inputs)
  end

  def jason_formatter_exs_setup(%Project{} = project) do
    inputs = [
      inputs: ["mix.exs", "{bench,lib,test}/**/*.{ex,exs}"]
    ]

    FormatterExs.create_project_formatter(project, inputs)
  end

  def learn_elixir_post_checkout(%Project{} = project) do
    Logger.info("Running post-checkout step for learn-elixir repository...")
    path = Project.path(project)

    # The file examples/lists/sum1.exs has syntax errors
    with {_output, 0} <-
           System.shell("git rm examples/lists/sum1.exs", cd: path, stderr_to_stdout: true),
         {_output, 0} <-
           System.shell(~s(git commit -m "Remove file with syntax errors"),
             cd: path,
             stderr_to_stdout: true
           ) do
      :ok
    else
      {output, _} ->
        {:error, "Failed to run post-checkout step for learn-elixir: #{output}"}
    end
  end

  def phoenix_formatter_exs_setup(%Project{} = project) do
    inputs = [
      inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"]
    ]

    FormatterExs.update_project_formatter(project, inputs)
  end

  def run_asdf_install(%Project{} = project) do
    Logger.info("Running 'asdf install', for #{project.name} repository...")

    path = Project.path(project)

    case System.shell("asdf install", cd: path, stderr_to_stdout: true) do
      {_output1, 0} ->
        :ok

      {output, _} ->
        {:error, "Failed to run post-checkout step for #{project.name}: #{output}"}
    end
  end

  def run_asdf_mix(%Project{} = project, command) do
    path = Project.path(project)
    System.shell("asdf exec mix #{command}", cd: path, stderr_to_stdout: true)
  end

  def run_mix_local_hex(%Project{} = project) do
    Logger.info("Running 'mix local.hex --force' for #{project.name} repository...")

    path = Project.path(project)

    case System.cmd("mix", ["local.hex", "--force"], cd: path, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _} ->
        {:error, "Failed to run 'mix local.hex' for #{project.name}: #{output}"}
    end
  end

  def run_mix_local_rebar(%Project{} = project) do
    Logger.info("Running 'mix local.rebar --force' for #{project.name} repository...")

    path = Project.path(project)

    case System.cmd("mix", ["local.rebar", "--force"], cd: path, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _} ->
        {:error, "Failed to run 'mix local.rebar' for #{project.name}: #{output}"}
    end
  end
end
