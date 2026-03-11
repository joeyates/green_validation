defmodule GreenValidation.Hexpm.Package do
  @derive Jason.Encoder
  @enforce_keys [:name, :recent_downloads, :description, :repo_url]
  defstruct [:name, :recent_downloads, :description, :repo_url]
end
