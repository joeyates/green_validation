defmodule GreenValidation.Github.Repo do
  @derive Jason.Encoder
  @enforce_keys [:name, :owner, :stars, :url]
  defstruct [
    :name,
    :owner,
    :stars,
    :url
  ]
end
