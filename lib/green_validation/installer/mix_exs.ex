defmodule GreenValidation.Installer.MixExs do
  @moduledoc """
  Handles modifications to `mix.exs` for temporary installation of Green formatter.
  """

  alias GreenValidation.Project

  @spec add_dependency(Project.t(), tuple()) :: :ok
  def add_dependency(%Project{} = project, dependency) do
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
