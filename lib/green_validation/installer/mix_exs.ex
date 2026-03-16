defmodule GreenValidation.Installer.MixExs do
  @moduledoc """
  Handles modifications to `mix.exs` for temporary installation of Green formatter.
  """

  alias GreenValidation.Project

  @spec ensure_mix_exs(Project.t()) :: :none | :created
  def ensure_mix_exs(%Project{} = project) do
    project_path = Project.path(project)
    mix_path = Path.join(project_path, "mix.exs")

    if File.exists?(mix_path) do
      :none
    else
      module = Project.module_name(project)

      content = """
      defmodule #{module}.MixProject do
        use Mix.Project

        def project do
          [
            app: :elixir,
            version: System.version(),
            build_per_environment: false,
            deps: []
          ]
        end
      end
      """

      File.write!(mix_path, content)

      :created
    end
  end

  @type dependency_option :: {:path, String.t()}
  @type dependency ::
          {atom(), String.t()}
          | {atom(), String.t(), [dependency_option]}
          | {atom(), [dependency_option]}

  @spec add_dependency(Project.t(), dependency) :: :none | :created | :updated
  def add_dependency(%Project{mix_exs_add_dependency: {mod, fun}} = project, dependency) do
    apply(mod, fun, [project, dependency])
  end

  def add_dependency(%Project{} = project, dependency) do
    project_path = Project.path(project)
    mix_path = Path.join(project_path, "mix.exs")

    if File.exists?(mix_path) do
      mix_path
      |> File.read!()
      |> add_dependency_to_content(dependency)
      |> then(&File.write!(mix_path, &1))

      :updated
    else
      create_with_dependency(project, dependency)
    end
  end

  def create_with_dependency(%Project{} = project, dependency) do
    project_path = Project.path(project)
    mix_path = Path.join(project_path, "mix.exs")
    module = Project.module_name(project)

    content = """
    defmodule #{module}.MixProject do
      use Mix.Project

      def project do
        [
          app: :elixir,
          version: System.version(),
          build_per_environment: false,
          deps: deps()
        ]
      end

      defp deps do
        [
          #{inspect(dependency)}
        ]
      end
    end
    """

    File.write!(mix_path, content)

    :created
  end

  @spec add_dependency_to_content(String.t(), dependency) :: String.t()
  def add_dependency_to_content(content, dependency) when is_binary(content) do
    if Regex.match?(~r"defp? deps", content) do
      content
      |> remove_existing_dependency(elem(dependency, 0))
      |> insert_dependency(dependency)
      |> reformat()
    else
      content
      |> add_deps_block(dependency)
      |> add_deps_call_to_project()
      |> reformat()
    end
  end

  @spec reset(Project.t(), :created | :updated | :none) :: :ok | {:error, String.t()}
  def reset(%Project{} = project, modification_action) do
    case modification_action do
      :created -> remove_mix_exs(project)
      :updated -> reset_mix_exs(project)
      :none -> :ok
    end
  end

  defp reset_mix_exs(%Project{} = project) do
    project_path = Project.path(project)

    case System.cmd("git", ["reset", "mix.exs"],
           cd: project_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, _} ->
        {:error, "Failed to reset mix.exs: #{output}"}
    end
  end

  defp remove_mix_exs(%Project{} = project) do
    project_path = Project.path(project)

    case System.cmd("rm", ["-f", "mix.exs"],
           cd: project_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, _} ->
        {:error, "Failed to reset mix.exs: #{output}"}
    end
  end

  @spec reformat(String.t()) :: String.t()
  def reformat(content) do
    content
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  @spec add_deps_block(String.t(), dependency) :: String.t()
  defp add_deps_block(content, dependency) do
    String.replace(content, ~r/\nend\s*$/, """


      defp deps() do
        [
          #{inspect(dependency)}
        ]
      end
    end
    """)
  end

  @spec add_deps_call_to_project(String.t()) :: String.t()
  defp add_deps_call_to_project(content) do
    String.replace(content, ~r/(def project(\(\))? do[\s\n]*\[)/, "\\1\n      deps: deps(),")
  end

  @spec remove_existing_dependency(String.t(), atom()) :: String.t()
  defp remove_existing_dependency(content, dep_name) do
    regex = ~r/^\s*{:\s*#{dep_name}\s*,.*?}\s*,?\s*$/m
    String.replace(content, regex, "")
  end

  @spec insert_dependency(String.t(), tuple()) :: String.t()
  defp insert_dependency(content, dependency) do
    regex = ~r/
      (defp?\sdeps(?:\(\))?\s+do\s*)
      \[\s*           # Start of list
    /sx
    dep_string = inspect(dependency)

    Regex.replace(
      regex,
      content,
      fn _match, def_start ->
        """
        #{def_start}
          [
            #{dep_string},
        """
      end
    )
  end
end
