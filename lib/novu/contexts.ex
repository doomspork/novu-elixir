defmodule Novu.Contexts do
  @moduledoc """
  Provide access to the Novu Contexts API.

  Contexts are typed entities (for example a tenant, app or workspace) used to
  scope triggers, preferences and the inbox in multi-tenant setups.

  A context is identified by its `type` and `id`, and is referenced elsewhere in
  the API as a `"type:id"` key. For example the context with type `"tenant"` and
  id `"acme"` is the key `"tenant:acme"`. That format is what the `contextKeys`
  filters accepted by other endpoints expect (such as the `:context_keys` option
  of `Novu.Topics.list_topic_subscriptions/2`).

  Both `type` and `id` must be lowercase alphanumeric with optional separators.
  """

  alias Novu.Http

  @list_params [
    after: "after",
    before: "before",
    limit: "limit",
    order_direction: "orderDirection",
    order_by: "orderBy",
    include_cursor: "includeCursor",
    id: "id",
    search: "search"
  ]

  @doc """
  Create a context. Returns a 409 error if the context already exists.

  ## Options

    * `:data` - custom data map to associate with the context
    * `:bridge_url` - bridge URL override for agent connect

  [API Documentation](https://docs.novu.co/api-reference/contexts/create-a-context)
  """
  @spec create_context(type :: String.t(), id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def create_context(type, id, opts \\ []) do
    body =
      %{type: type, id: id}
      |> add_optional_value(:data, opts[:data])
      |> add_optional_value(:bridgeUrl, opts[:bridge_url])

    Http.post("/v2/contexts", body)
  end

  @doc """
  List contexts (cursor paginated).

  ## Options

    * `:after`, `:before`, `:limit`, `:order_direction`, `:order_by`, `:include_cursor` - pagination and sorting
    * `:id` - filter contexts by id
    * `:search` - search contexts by type or id (partial match)

  [API Documentation](https://docs.novu.co/api-reference/contexts/list-all-contexts)
  """
  @spec list_contexts(opts :: Keyword.t()) :: Http.response()
  def list_contexts(opts \\ []) do
    params = for {opt, name} <- @list_params, (value = opts[opt]) != nil, into: %{}, do: {name, value}
    Http.get("/v2/contexts", params)
  end

  @doc """
  Retrieve a context by type and id.

  [API Documentation](https://docs.novu.co/api-reference/contexts/retrieve-a-context)
  """
  @spec get_context(type :: String.t(), id :: String.t()) :: Http.response()
  def get_context(type, id), do: type |> context_path(id) |> Http.get()

  @doc """
  Update a context. Only the data (and optionally the bridge URL) is updated.

  The API requires `:data`, which replaces the existing data.

  ## Options

    * `:data` - custom data map (replaces existing data)
    * `:bridge_url` - bridge URL override for agent connect

  [API Documentation](https://docs.novu.co/api-reference/contexts/update-a-context)
  """
  @spec update_context(type :: String.t(), id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update_context(type, id, opts \\ []) do
    body =
      %{}
      |> add_optional_value(:data, opts[:data])
      |> add_optional_value(:bridgeUrl, opts[:bridge_url])

    type |> context_path(id) |> Http.patch(body)
  end

  @doc """
  Delete a context by type and id.

  [API Documentation](https://docs.novu.co/api-reference/contexts/delete-a-context)
  """
  @spec delete_context(type :: String.t(), id :: String.t()) :: Http.response()
  def delete_context(type, id), do: type |> context_path(id) |> Http.delete()

  defp context_path(type, id), do: "/v2/contexts/#{Http.path_segment(type)}/#{Http.path_segment(id)}"

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
