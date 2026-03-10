defmodule GreenValidation.Installer.FormatterExs do
  alias GreenValidation.Project

  @line_length 98

  def update_project_formatter(project, keyword) do
    formatter_exs_path = project |> Project.path() |> Path.join(".formatter.exs")

    updated_code =
      formatter_exs_path
      |> File.read!()
      |> update_formatter_exs_code(keyword)

    File.write!(formatter_exs_path, updated_code)

    :ok
  end

  def update_formatter_exs_code(code, keyword) do
    to_quoted_opts =
      [
        unescape: false,
        literal_encoder: &{:ok, {:__block__, &2, [&1]}},
        token_metadata: true,
        emit_warnings: false
      ]

    {:ok, quoted, comments} = Code.string_to_quoted_with_comments(code, to_quoted_opts)
    code_is_keyword_only = keyword_only?(quoted)
    pairs = extract_pairs(quoted, code_is_keyword_only)
    pairs = merge_keywords(pairs, keyword)

    to_algebra_opts = [comments: comments]

    quoted
    |> replace_pairs(pairs, code_is_keyword_only)
    |> Code.Formatter.to_algebra(to_algebra_opts)
    |> Inspect.Algebra.format(@line_length)
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  defp keyword_only?({:__block__, _ctx, [[]]}), do: true

  defp keyword_only?(
         {:__block__, _ctx, [[{{:__block__, [format: :keyword, line: _], _}, _} | _]]}
       ) do
    true
  end

  defp keyword_only?(_), do: false

  defp extract_pairs({:__block__, _ctx, [pairs]}, true) do
    pairs
  end

  defp extract_pairs({:__block__, _ctx, expressions}, false) do
    last = List.last(expressions)
    extract_pairs(last, true)
  end

  defp replace_pairs({:__block__, ctx, [_pairs]}, new_pairs, true) do
    {:__block__, ctx, [new_pairs]}
  end

  defp replace_pairs({:__block__, ctx, expressions}, new_pairs, false) do
    last = List.last(expressions)
    new_last = replace_pairs(last, new_pairs, true)
    {:__block__, ctx, List.replace_at(expressions, length(expressions) - 1, new_last)}
  end

  defp merge_keywords(quoted_pairs, keyword) do
    to_quoted_opts =
      [
        unescape: false,
        literal_encoder: &{:ok, {:__block__, &2, [&1]}},
        token_metadata: true,
        emit_warnings: false
      ]

    Enum.reduce(
      keyword,
      quoted_pairs,
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
  end
end
