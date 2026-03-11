defmodule GreenValidation.Github.Repo do
  @derive Jason.Encoder
  @enforce_keys [:default_branch, :name, :owner, :stars, :url]
  defstruct [
    :default_branch,
    :name,
    :owner,
    :stars,
    :url
  ]
end
