defmodule GreenValidation.StyleSource do
  @moduledoc """
  Registry of the four "sources of truth" for Elixir style that are compared:
  `mix format`, Lexmag's style guide, Credo's style guide and christopheradams'
  "The Elixir Style Guide".

  Each source is a map with:

    * `:id` — the source key used throughout the pipeline
    * `:name` — human-readable name
    * `:repo_url` — where the source lives
    * `:raw_url` — raw markdown URL for the prose guides (`nil` for `mix_format`)
    * `:branch` — the branch the `:raw_url` points at (`nil` for `mix_format`)
  """

  @type id :: :mix_format | :lexmag | :credo | :christopher_adams

  @type t :: %{
          id: id(),
          name: String.t(),
          repo_url: String.t(),
          raw_url: String.t() | nil,
          branch: String.t() | nil
        }

  @sources [
    %{
      id: :mix_format,
      name: "mix format",
      repo_url: "https://github.com/elixir-lang/elixir",
      raw_url: nil,
      branch: nil
    },
    %{
      id: :lexmag,
      name: "Lexmag's Elixir Style Guide",
      repo_url: "https://github.com/lexmag/elixir-style-guide",
      raw_url: "https://raw.githubusercontent.com/lexmag/elixir-style-guide/master/README.md",
      branch: "master"
    },
    %{
      id: :credo,
      name: "Credo's Elixir Style Guide",
      repo_url: "https://github.com/rrrene/elixir-style-guide",
      raw_url: "https://raw.githubusercontent.com/rrrene/elixir-style-guide/master/README.md",
      branch: "master"
    },
    %{
      id: :christopher_adams,
      name: "The Elixir Style Guide",
      repo_url: "https://github.com/christopheradams/elixir_style_guide",
      raw_url:
        "https://raw.githubusercontent.com/christopheradams/elixir_style_guide/master/README.md",
      branch: "master"
    }
  ]

  @doc """
  Returns all four sources.
  """
  @spec all() :: [t()]
  def all(), do: @sources

  @doc """
  Returns the prose guides — the three sources with vendorable markdown, i.e. every
  source except `mix_format`.
  """
  @spec prose() :: [t()]
  def prose(), do: Enum.filter(@sources, &(&1.raw_url != nil))
end
