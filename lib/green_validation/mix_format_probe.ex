defmodule GreenValidation.MixFormatProbe do
  @moduledoc """
  Classifies, empirically, how `mix format` treats a rule by running a probe through
  `Code.format_string!/2`.

  A probe is a map `%{input: <violates the rule>, expected: <satisfies the rule>}` with
  an optional `:level`:

    * `:string` (default) — compares `Code.format_string!/2` output, ignoring a trailing
      newline (the in-memory formatter never emits one).
    * `:file` — mirrors `Mix.Tasks.Format.elixir_format/2`: formats, then appends a single
      trailing newline for non-empty content, and compares exactly. This is the file
      content `mix format` actually writes, so it can observe end-of-file behaviour the
      `:string` level can't.

  `classify/1` returns:

    * `:enforced` — the formatter rewrites `input` into `expected`.
    * `:not_enforced` — the formatter parses `input` but leaves it unchanged.
    * `:indeterminate` — the input doesn't parse, the `expected` form isn't a fixed point,
      or the formatter produces some third form (the probe isn't isolated).
  """

  @type level :: :string | :file
  @type status :: :enforced | :not_enforced | :indeterminate

  @spec classify(%{
          required(:input) => String.t(),
          required(:expected) => String.t(),
          optional(:level) => level()
        }) :: status()
  def classify(%{input: input, expected: expected} = probe) do
    level = Map.get(probe, :level, :string)

    with {:ok, formatted} <- safe_format(input, level),
         {:ok, formatted_expected} <- safe_format(expected, level),
         true <- formatted_expected == target(expected, level) do
      cond do
        formatted == target(expected, level) -> :enforced
        formatted == target(input, level) -> :not_enforced
        true -> :indeterminate
      end
    else
      _ -> :indeterminate
    end
  end

  @spec enforced?(%{input: String.t(), expected: String.t()}) :: boolean()
  def enforced?(probe), do: classify(probe) == :enforced

  defp safe_format(string, level) do
    {:ok, format_content(string, level)}
  rescue
    _ -> :error
  end

  defp format_content(string, :string) do
    string |> Code.format_string!() |> IO.iodata_to_binary() |> normalize()
  end

  # Mirrors Mix.Tasks.Format.elixir_format/2: format, then append a trailing newline for
  # non-empty content — the file content `mix format` writes to disk.
  defp format_content(string, :file) do
    case string |> Code.format_string!() |> IO.iodata_to_binary() do
      "" -> ""
      content -> IO.iodata_to_binary([content, ?\n])
    end
  end

  defp target(string, :string), do: normalize(string)
  defp target(string, :file), do: string

  defp normalize(string), do: String.trim_trailing(string, "\n")
end
