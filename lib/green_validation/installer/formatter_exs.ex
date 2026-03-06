defmodule GreenValidation.Installer.FormatterExs do
  alias GreenValidation.Project

  @line_length 98

  def update_project_formatter(project, keyword) do
    project_path = Project.path(project)
    formatter_path = Path.join(project_path, ".formatter.exs")
    code = File.read!(formatter_path)

    to_quoted_opts =
      [
        unescape: false,
        literal_encoder: &{:ok, {:__block__, &2, [&1]}},
        token_metadata: true,
        emit_warnings: false
      ]

    {:ok, quoted, comments} = Code.string_to_quoted_with_comments(code, to_quoted_opts)
    {_blk, context, [pairs]} = quoted

    pairs =
      Enum.reduce(
        keyword,
        pairs,
        fn {key, value}, acc ->
          {:__block__, _ctx, [[block]]} =
            Code.string_to_quoted!("[#{key}: #{inspect(value)}]", to_quoted_opts)

          index = Enum.find_index(acc, fn {{:__block__, _ctx, [key1]}, _value} -> key1 == key end)

          if index do
            List.replace_at(acc, index, block)
          else
            acc ++ [block]
          end
        end
      )

    to_algebra_opts = [comments: comments]

    updated_code =
      {:__block__, context, [pairs]}
      |> Code.Formatter.to_algebra(to_algebra_opts)
      |> Inspect.Algebra.format(@line_length)
      |> IO.iodata_to_binary()
      |> Kernel.<>("\n")

    File.write!(formatter_path, updated_code)

    :ok
  end
end
