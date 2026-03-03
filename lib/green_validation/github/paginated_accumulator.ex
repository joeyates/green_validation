defmodule GreenValidation.Github.PaginatedAccumulator do
  @moduledoc """
  A helper module to accumulate paginated responses from the Github API.
  """

  defstruct [
    :headers,
    limit: 100,
    items: []
  ]

  def new(), do: %__MODULE__{}

  def build_response(%__MODULE__{} = acc) do
    items = Enum.take(acc.items, acc.limit)
    %Req.Response{headers: acc.headers, body: %{"items" => items}}
  end

  def continue?(%__MODULE__{items: items, limit: limit}) do
    length(items) < limit
  end
end
