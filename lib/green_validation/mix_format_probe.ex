defmodule GreenValidation.MixFormatProbe do
  @moduledoc """
  Decides empirically whether `mix format` enforces a rule, by running a probe through
  `Code.format_string!/2`.

  A probe is a map `%{input: <violates the rule>, expected: <satisfies the rule>}`.
  `enforced?/1` formats `input` and classifies the result:

    * equals `expected` → the formatter applies the rule (`true`)
    * equals `input` → the formatter parses the code but leaves it alone (`false`)
    * anything else → the probe is not isolated (it exercises more than one rule), so it
      raises — the probe must be split until a single change is attributable.

  Comparisons ignore a trailing newline, since `Code.format_string!/2` does not emit one.
  """

  @spec enforced?(%{input: String.t(), expected: String.t()}) :: boolean()
  def enforced?(%{input: input, expected: expected}) do
    formatted = format(input)

    cond do
      formatted == normalize(expected) -> true
      formatted == normalize(input) -> false
      true -> raise ArgumentError, non_isolated_message(input, expected, formatted)
    end
  end

  defp format(string) do
    string
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> normalize()
  end

  defp normalize(string), do: String.trim_trailing(string, "\n")

  defp non_isolated_message(input, expected, formatted) do
    "non-isolated mix format probe: formatting #{inspect(input)} produced " <>
      "#{inspect(formatted)}, which is neither the input nor the expected " <>
      "#{expected |> normalize() |> inspect()}; the probe exercises more than one rule"
  end
end
