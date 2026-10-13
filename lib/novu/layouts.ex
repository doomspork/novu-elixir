defmodule Novu.Layouts do
  @moduledoc """
  Provide access to the Novu Layouts API (`/v2/layouts`).

  Functions that take `attrs` accept a plain map in the API's camelCase shape
  and pass it through unchanged.
  """

  alias Novu.Http

  @doc """
  Retrieves a list of layouts with optional filtering and pagination.

  ## Options

    * `:limit` - number of items to return per page
    * `:offset` - number of items to skip
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to sort by
    * `:query` - search query

  [API Documentation](https://docs.novu.co/api-reference/layouts/list-all-layouts)
  """
  @spec list_layouts(opts :: Keyword.t()) :: Http.response()
  def list_layouts(opts \\ []) do
    params =
      %{}
      |> add_optional_value(:limit, opts[:limit])
      |> add_optional_value(:offset, opts[:offset])
      |> add_optional_value(:orderDirection, opts[:order_direction])
      |> add_optional_value(:orderBy, opts[:order_by])
      |> add_optional_value(:query, opts[:query])

    Http.get("/v2/layouts", params)
  end

  @doc """
  Creates a new layout.

  `attrs` is passed through as the request body. Required keys: `layoutId` and
  `name`. Optional: `isTranslationEnabled`.

  [API Documentation](https://docs.novu.co/api-reference/layouts/create-a-layout)
  """
  @spec create_layout(attrs :: map()) :: Http.response()
  def create_layout(attrs), do: Http.post("/v2/layouts", attrs)

  @doc """
  Retrieves a layout by its identifier.

  [API Documentation](https://docs.novu.co/api-reference/layouts/retrieve-a-layout)
  """
  @spec get_layout(layout_id :: String.t()) :: Http.response()
  def get_layout(layout_id), do: layout_id |> layout_path() |> Http.get()

  @doc """
  Updates an existing layout.

  `attrs` is passed through as the request body. Required key: `name`.
  Optional: `isTranslationEnabled` and `controlValues`.

  [API Documentation](https://docs.novu.co/api-reference/layouts/update-a-layout)
  """
  @spec update_layout(layout_id :: String.t(), attrs :: map()) :: Http.response()
  def update_layout(layout_id, attrs), do: layout_id |> layout_path() |> Http.put(attrs)

  @doc """
  Deletes a layout.

  [API Documentation](https://docs.novu.co/api-reference/layouts/delete-a-layout)
  """
  @spec delete_layout(layout_id :: String.t()) :: Http.response()
  def delete_layout(layout_id), do: layout_id |> layout_path() |> Http.delete()

  @doc """
  Duplicates a layout, creating a new layout with the content of the original.

  `attrs` is passed through as the request body. Required key: `name`.
  Optional: `layoutId` and `isTranslationEnabled`.

  [API Documentation](https://docs.novu.co/api-reference/layouts/duplicate-a-layout)
  """
  @spec duplicate_layout(layout_id :: String.t(), attrs :: map()) :: Http.response()
  def duplicate_layout(layout_id, attrs), do: Http.post(layout_path(layout_id) <> "/duplicate", attrs)

  @doc """
  Generates a preview for a layout.

  `attrs` is passed through as the request body. Optional keys:
  `controlValues` and `previewPayload`.

  [API Documentation](https://docs.novu.co/api-reference/layouts/generate-layout-preview)
  """
  @spec preview_layout(layout_id :: String.t(), attrs :: map()) :: Http.response()
  def preview_layout(layout_id, attrs), do: Http.post(layout_path(layout_id) <> "/preview", attrs)

  @doc """
  Retrieves the workflows that use the specified layout.

  [API Documentation](https://docs.novu.co/api-reference/layouts/get-layout-usage)
  """
  @spec get_layout_usage(layout_id :: String.t()) :: Http.response()
  def get_layout_usage(layout_id), do: Http.get(layout_path(layout_id) <> "/usage")

  defp layout_path(layout_id), do: "/v2/layouts/#{Http.path_segment(layout_id)}"

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
