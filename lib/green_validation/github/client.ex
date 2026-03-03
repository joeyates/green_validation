defmodule GreenValidation.Github.Client do
  @moduledoc """
  This module is responsible for handling the communication with the Github API.
  """

  import URI, only: [encode_www_form: 1]

  alias GreenValidation.Github.PaginatedAccumulator

  @github_url "https://api.github.com"

  def get(path, params \\ nil) do
    base = Path.join(@github_url, path)
    url =
      if params do
        encoded = URI.encode_query(params)
        "#{base}?#{encoded}"
      else
        base
      end

    case Req.get(url) do
      {:ok, resp} -> {:ok, resp}
      {:error, _reason} -> {:error, "Failed to fetch data from Github"}
    end
  end

  def get_paginated(path, params \\ nil, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    handle_paginated_response(get(path, params), %PaginatedAccumulator{limit: limit})
  end

  defp handle_paginated_response(
    {:ok, %Req.Response{status: status, headers: %{"link" => [link]}} = response}, acc
  ) when status == 200 do
    first_headers = acc.headers || response.headers
    all_items = acc.items ++ response.body["items"]
    acc = %{acc | headers: first_headers, items: all_items}
    next =
      link
      |> parse_link()
      |> Map.get("next")

    cond do
      is_nil(next) ->
        {:ok, PaginatedAccumulator.build_response(acc)}
      not PaginatedAccumulator.continue?(acc) ->
        {:ok, PaginatedAccumulator.build_response(acc)}
      true ->
        get_next_page(next, acc)
    end
  end

  defp handle_paginated_response({:ok, %Req.Response{status: status} = response}, acc) when status == 200 do
    first_headers = acc.headers || response.headers
    all_items = acc.items ++ response.body["items"]
    acc = %{acc | headers: first_headers, items: all_items}
    {:ok, PaginatedAccumulator.build_response(acc)}
  end

  defp handle_paginated_response({:ok, %Req.Response{status: status, body: body}}, _acc) when status >= 400 and status < 500 do
    message = body["message"] || "Failed to fetch data from Github"
    {:error, message}
  end

  defp handle_paginated_response(result, _acc), do: result

  defp get_next_page(next, acc) do
    handle_paginated_response(Req.get(next), acc)
  end

  def encode_search(search) when is_list(search) do
    Enum.map_join(search, " ", fn {key, value} ->
      encode_www_form(Kernel.to_string(key)) <>
        ":" <>
          encode_www_form(Kernel.to_string(value))
    end)
  end

  defp parse_link(link) do
    link
    |> String.split(", ")
    |> Enum.map(fn part ->
      [url_part, rel_part] = String.split(part, "; ")
      [rel] = Regex.run(~r/"([^"]+)/, rel_part, capture: :all_but_first)
      [url] = Regex.run(~r/<([^>]+)/, url_part, capture: :all_but_first)
      {rel, url}
    end)
    |> Enum.into(%{})
  end
end
