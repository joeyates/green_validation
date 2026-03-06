defmodule GreenValidation.Installer.MixExs do
  @moduledoc """
  Handles modifications to `mix.exs` for temporary installation of Green formatter.
  """

  alias GreenValidation.Project

  def ensure_mix_exs(%Project{has_mix_exs: true} = project) do
    project_path = Project.path(project)
    mix_path = Path.join(project_path, "mix.exs")

    if !File.exists?(mix_path) do
      raise "mix.exs not found in #{project_path}"
    end

    :ok
  end

  def ensure_mix_exs(%Project{has_mix_exs: false} = project) do
    project_path = Project.path(project)
    mix_path = Path.join(project_path, "mix.exs")

    if File.exists?(mix_path) do
      raise "mix.exs already exists in #{project_path}"
    end

    content = """
    defmodule #{Macro.camelize(project.name)}.MixProject do
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

    :ok
  end

  @spec add_dependency(Project.t(), tuple()) :: :ok
  def add_dependency(%Project{has_mix_exs: true} = project, dependency) do
    project_path = Project.path(project)
    mix_path = Path.join(project_path, "mix.exs")

    if !File.exists?(mix_path) do
      raise "mix.exs not found in #{project_path}"
    end

    mix_path
    |> File.read!()
    |> add_dependency(dependency)
    |> then(&File.write!(mix_path, &1))

    :ok
  end

  def add_dependency(%Project{has_mix_exs: false} = project, dependency) do
    project_path = Project.path(project)
    mix_path = Path.join(project_path, "mix.exs")
    project_module = Macro.camelize(project.name)

    content = """
    defmodule #{project_module}.MixProject do
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
  end

  @spec add_dependency(String.t(), tuple()) :: String.t()
  def add_dependency(content, dependency) when is_binary(content) do
    if String.contains?(content, "defp deps") do
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

  @spec reset_mix_exs(Project.t()) :: :ok | {:error, String.t()}
  def reset_mix_exs(%Project{has_mix_exs: true} = project) do
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

  def reset_mix_exs(%Project{has_mix_exs: false} = project) do
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
  defp reformat(content) do
    content
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  @spec add_deps_block(String.t(), tuple()) :: String.t()
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
      (?<def_start>defp\sdeps(?:\(\))?\s+do\s*)
      \[\s*           # Start of list
      (?<libs>.*?)
      \s*]\s*         # End of list
      (?<def_end>\s*end)
    /sx
    dep_string = inspect(dependency)

    Regex.replace(
      regex,
      content,
      fn _match, def_start, libs, def_end ->
        libs = String.trim(libs)

        list =
          if libs == "" do
            """
            [
              #{dep_string}
            ]
            """
          else
            """
            [
              #{libs},
              #{dep_string}
            ]
            """
          end

        "#{def_start}#{list}#{def_end}"
      end,
      capture: [:def_start, :open, :libs, :close, :def_end]
    )
  end
end
