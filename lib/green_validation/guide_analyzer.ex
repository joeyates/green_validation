defmodule GreenValidation.GuideAnalyzer do
  @moduledoc """
  Shared analysis for the prose style guides (Lexmag, Credo, christopheradams).

  Given a source, the vendored guide markdown, and a curated `[{master_id, anchor}]`
  mapping, `analyze/3` returns:

    * `:rules` — `%{id, proposed: true, reference}` for each mapped rule, where the
      reference links into the guide at the anchor.
    * `:unmapped` — guide rule anchors (`<a name="...">`) the mapping does not cover.
      These feed the refinement loop: each is a guide rule not yet in the master list.
    * `:drift` — mapping entries whose anchor no longer resolves in the guide (a typo or
      a guide that changed since the mapping was written).

  Anchors resolve against both the guide's `<a name="...">` HTML anchors (which all three
  guides use per rule) and its markdown heading slugs.
  """

  @anchor_regex ~r/<a name="([^"]+)"/
  @heading_regex ~r/^\#{1,6}\s+(.+?)\s*$/m

  @spec analyze(map(), String.t(), [{atom(), String.t()}]) :: %{
          rules: [map()],
          unmapped: [map()],
          drift: [map()]
        }
  def analyze(source, markdown, mapping) do
    rule_anchors = html_anchors(markdown)
    resolvable = MapSet.union(rule_anchors, heading_anchors(markdown))

    rules =
      Enum.map(mapping, fn {id, anchor} ->
        %{id: id, proposed: true, reference: reference(source, anchor)}
      end)

    drift =
      mapping
      |> Enum.reject(fn {_id, anchor} -> MapSet.member?(resolvable, anchor) end)
      |> Enum.map(fn {id, anchor} -> %{id: id, anchor: anchor} end)

    mapped = MapSet.new(mapping, fn {_id, anchor} -> anchor end)

    unmapped =
      rule_anchors
      |> MapSet.difference(mapped)
      |> Enum.sort()
      |> Enum.map(&%{anchor: &1})

    %{rules: rules, unmapped: unmapped, drift: drift}
  end

  defp reference(%{repo_url: repo_url}, anchor), do: "#{repo_url}##{anchor}"

  defp html_anchors(markdown) do
    @anchor_regex
    |> Regex.scan(markdown)
    |> Enum.map(fn [_, anchor] -> anchor end)
    |> MapSet.new()
  end

  defp heading_anchors(markdown) do
    @heading_regex
    |> Regex.scan(markdown)
    |> Enum.map(fn [_, heading] -> slug(heading) end)
    |> MapSet.new()
  end

  defp slug(heading) do
    heading
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9 \-]/u, "")
    |> String.trim()
    |> String.replace(~r/\s+/, "-")
  end
end
