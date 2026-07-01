defmodule GreenValidation.GuideAnalyzerTest do
  use ExUnit.Case, async: true

  alias GreenValidation.GuideAnalyzer

  @source %{
    id: :lexmag,
    name: "Lexmag's Elixir Style Guide",
    repo_url: "https://example.com/guide"
  }

  @markdown """
  # Title

  <a name="rule-one"></a>
  Some rule.

  <a name="rule-two"></a>
  Another rule.

  ## Some Section
  """

  describe "analyze/3" do
    test "emits a proposed rule with a reference for each mapped anchor" do
      mapping = [{:max_line_length, "rule-one"}]

      result = GuideAnalyzer.analyze(@source, @markdown, mapping)
      rule = Enum.find(result.rules, &(&1.id == :max_line_length))

      assert rule.proposed
      assert rule.reference == "https://example.com/guide#rule-one"
    end

    test "reports a mapping anchor that does not resolve as drift" do
      mapping = [{:max_line_length, "rule-one"}, {:two_space_indentation, "missing-anchor"}]

      result = GuideAnalyzer.analyze(@source, @markdown, mapping)

      assert Enum.any?(result.drift, &(&1.anchor == "missing-anchor"))
      refute Enum.any?(result.drift, &(&1.anchor == "rule-one"))
    end

    test "lists guide rule anchors that the mapping does not cover as unmapped" do
      mapping = [{:max_line_length, "rule-one"}]

      result = GuideAnalyzer.analyze(@source, @markdown, mapping)

      assert Enum.any?(result.unmapped, &(&1.anchor == "rule-two"))
      refute Enum.any?(result.unmapped, &(&1.anchor == "rule-one"))
    end
  end
end
