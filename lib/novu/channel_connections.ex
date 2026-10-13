defmodule Novu.ChannelConnections do
  @moduledoc """
  Provide access to the Novu Channel Connections API (`/v1/channel-connections`).

  Bodies are polymorphic by provider, so functions that take `attrs` accept a
  plain map in the API's camelCase shape and pass it through unchanged.
  """

  alias Novu.Http

  @doc """
  Lists channel connections.

  ## Options

    * `:after` - cursor to fetch results after
    * `:before` - cursor to fetch results before
    * `:limit` - number of items to return (max 100)
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to order by
    * `:include_cursor` - include the cursor item in the response
    * `:subscriber_id` - filter by subscriber ID
    * `:connection_mode` - `"subscriber"` or `"shared"`
    * `:channel` - filter by channel type
    * `:provider_id` - filter by provider identifier
    * `:integration_identifier` - filter by integration identifier
    * `:context_keys` - list of context keys (format `"type:id"`)

  [API Documentation](https://docs.novu.co/api-reference/channel-connections/list-all-channel-connections)
  """
  @spec list_channel_connections(opts :: Keyword.t()) :: Http.response()
  def list_channel_connections(opts \\ []) do
    params =
      %{}
      |> add_optional_value(:after, opts[:after])
      |> add_optional_value(:before, opts[:before])
      |> add_optional_value(:limit, opts[:limit])
      |> add_optional_value(:orderDirection, opts[:order_direction])
      |> add_optional_value(:orderBy, opts[:order_by])
      |> add_optional_value(:includeCursor, opts[:include_cursor])
      |> add_optional_value(:subscriberId, opts[:subscriber_id])
      |> add_optional_value(:connectionMode, opts[:connection_mode])
      |> add_optional_value(:channel, opts[:channel])
      |> add_optional_value(:providerId, opts[:provider_id])
      |> add_optional_value(:integrationIdentifier, opts[:integration_identifier])
      |> add_optional_value(:contextKeys, opts[:context_keys])

    Http.get("/v1/channel-connections", params)
  end

  @doc """
  Creates a channel connection.

  `attrs` is passed through as the request body. Required keys: `integrationIdentifier`, `workspace` (`id`, optional `name`, `botUserId`) and `auth` (`accessToken`, optional `refreshToken`, `expiresAt`, `refreshTokenExpiresAt`). Optional: `identifier`, `subscriberId`, `context` and `connectionMode`.

  [API Documentation](https://docs.novu.co/api-reference/channel-connections/create-a-channel-connection)
  """
  @spec create_channel_connection(attrs :: map()) :: Http.response()
  def create_channel_connection(attrs), do: Http.post("/v1/channel-connections", attrs)

  @doc """
  Retrieves a channel connection by its identifier.

  [API Documentation](https://docs.novu.co/api-reference/channel-connections/retrieve-a-channel-connection)
  """
  @spec get_channel_connection(identifier :: String.t()) :: Http.response()
  def get_channel_connection(identifier), do: identifier |> connection_path() |> Http.get()

  @doc """
  Updates a channel connection.

  `attrs` is passed through as the request body.

  [API Documentation](https://docs.novu.co/api-reference/channel-connections/update-a-channel-connection)
  """
  @spec update_channel_connection(identifier :: String.t(), attrs :: map()) :: Http.response()
  def update_channel_connection(identifier, attrs), do: identifier |> connection_path() |> Http.patch(attrs)

  @doc """
  Deletes a channel connection.

  [API Documentation](https://docs.novu.co/api-reference/channel-connections/delete-a-channel-connection)
  """
  @spec delete_channel_connection(identifier :: String.t()) :: Http.response()
  def delete_channel_connection(identifier), do: identifier |> connection_path() |> Http.delete()

  defp connection_path(identifier), do: "/v1/channel-connections/#{Http.path_segment(identifier)}"

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
