defmodule Novu.Agents do
  @moduledoc """
  Provide access to the Novu Agents API (`/v1/agents`).

  Functions that take `attrs` accept a plain map in the API's camelCase shape
  and pass it through unchanged. The deprecated `POST /v1/agents/:agentId/reply`
  endpoint is not supported.
  """

  alias Novu.Http

  @doc """
  Lists agents of the current environment with cursor pagination.

  ## Options

    * `:after` - cursor to start after
    * `:before` - cursor to end before
    * `:limit` - number of items to return
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to order by
    * `:include_cursor` - include the cursor item in the response
    * `:identifier` - partial, case-insensitive match on identifier

  [API Documentation](https://docs.novu.co/api-reference/agents/list-all-agents)
  """
  @spec list_agents(opts :: Keyword.t()) :: Http.response()
  def list_agents(opts \\ []) do
    params =
      opts
      |> pagination_params()
      |> add_optional_value(:identifier, opts[:identifier])

    Http.get("/v1/agents", params)
  end

  @doc """
  Creates an agent.

  `attrs` is passed through as the request body. Keys: `name`, `identifier`,
  `description`, `active`, `runtime` (`"self-hosted"` or `"managed"`) and
  `managedRuntime`.

  [API Documentation](https://docs.novu.co/api-reference/agents/create-an-agent)
  """
  @spec create_agent(attrs :: map()) :: Http.response()
  def create_agent(attrs), do: Http.post("/v1/agents", attrs)

  @doc """
  Retrieves an agent by its identifier.

  [API Documentation](https://docs.novu.co/api-reference/agents/retrieve-an-agent)
  """
  @spec get_agent(identifier :: String.t()) :: Http.response()
  def get_agent(identifier), do: identifier |> agent_path() |> Http.get()

  @doc """
  Updates an agent.

  `attrs` is passed through as the request body. Keys: `name`, `description`,
  `active`, `behavior`, `bridgeUrl`, `devBridgeUrl` and `devBridgeActive`.

  [API Documentation](https://docs.novu.co/api-reference/agents/update-an-agent)
  """
  @spec update_agent(identifier :: String.t(), attrs :: map()) :: Http.response()
  def update_agent(identifier, attrs), do: identifier |> agent_path() |> Http.patch(attrs)

  @doc """
  Deletes an agent.

  ## Options

    * `:delete_from_provider` - when `true`, also archives a managed-runtime
      agent on the provider side

  [API Documentation](https://docs.novu.co/api-reference/agents/delete-an-agent)
  """
  @spec delete_agent(identifier :: String.t(), opts :: Keyword.t()) :: Http.response()
  def delete_agent(identifier, opts \\ []) do
    params = add_optional_value(%{}, :deleteFromProvider, opts[:delete_from_provider])

    identifier |> agent_path() |> Http.delete(params: params)
  end

  @doc """
  Updates the bridge URL configuration of an agent.

  `attrs` is passed through as the request body. Keys: `bridgeUrl`,
  `devBridgeUrl` and `devBridgeActive`.

  [API Documentation](https://docs.novu.co/api-reference/agents/update-an-agent-bridge)
  """
  @spec update_agent_bridge(identifier :: String.t(), attrs :: map()) :: Http.response()
  def update_agent_bridge(identifier, attrs), do: Http.put(agent_path(identifier) <> "/bridge", attrs)

  @doc """
  Lists the integration links of an agent.

  ## Options

    * `:after` - cursor to start after
    * `:before` - cursor to end before
    * `:limit` - number of items to return
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to order by
    * `:include_cursor` - include the cursor item in the response
    * `:integration_identifier` - only links for this integration identifier

  [API Documentation](https://docs.novu.co/api-reference/agents/list-agent-integrations)
  """
  @spec list_agent_integrations(identifier :: String.t(), opts :: Keyword.t()) :: Http.response()
  def list_agent_integrations(identifier, opts \\ []) do
    params =
      opts
      |> pagination_params()
      |> add_optional_value(:integrationIdentifier, opts[:integration_identifier])

    Http.get(agent_path(identifier) <> "/integrations", params)
  end

  @doc """
  Links an agent to an integration.

  `attrs` is passed through as the request body. Keys: `integrationIdentifier`
  and `providerId`.

  [API Documentation](https://docs.novu.co/api-reference/agents/create-an-agent-integration)
  """
  @spec create_agent_integration(identifier :: String.t(), attrs :: map()) :: Http.response()
  def create_agent_integration(identifier, attrs), do: Http.post(agent_path(identifier) <> "/integrations", attrs)

  @doc """
  Updates which integration an agent-integration link points to.

  `attrs` is passed through as the request body. Required key:
  `integrationIdentifier`.

  [API Documentation](https://docs.novu.co/api-reference/agents/update-an-agent-integration)
  """
  @spec update_agent_integration(identifier :: String.t(), agent_integration_id :: String.t(), attrs :: map()) ::
          Http.response()
  def update_agent_integration(identifier, agent_integration_id, attrs),
    do: identifier |> integration_path(agent_integration_id) |> Http.patch(attrs)

  @doc """
  Deletes an agent-integration link.

  [API Documentation](https://docs.novu.co/api-reference/agents/delete-an-agent-integration)
  """
  @spec delete_agent_integration(identifier :: String.t(), agent_integration_id :: String.t()) :: Http.response()
  def delete_agent_integration(identifier, agent_integration_id),
    do: identifier |> integration_path(agent_integration_id) |> Http.delete()

  defp agent_path(identifier), do: "/v1/agents/#{Http.path_segment(identifier)}"

  defp integration_path(identifier, id), do: "#{agent_path(identifier)}/integrations/#{Http.path_segment(id)}"

  defp pagination_params(opts) do
    %{}
    |> add_optional_value(:after, opts[:after])
    |> add_optional_value(:before, opts[:before])
    |> add_optional_value(:limit, opts[:limit])
    |> add_optional_value(:orderDirection, opts[:order_direction])
    |> add_optional_value(:orderBy, opts[:order_by])
    |> add_optional_value(:includeCursor, opts[:include_cursor])
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
