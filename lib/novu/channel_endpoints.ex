defmodule Novu.ChannelEndpoints do
  @moduledoc """
  Provide access to the Novu Channel Endpoints API (`/v1/channel-endpoints`).

  Bodies are polymorphic by provider, so functions that take `attrs` accept a
  plain map in the API's camelCase shape and pass it through unchanged.
  """

  alias Novu.Http

  @doc """
  Lists channel endpoints.

  ## Options

    * `:after` - cursor to fetch results after
    * `:before` - cursor to fetch results before
    * `:limit` - number of items to return (max 100)
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to order by
    * `:include_cursor` - include the cursor item in the response
    * `:subscriber_id` - filter by subscriber ID
    * `:connection_identifier` - filter by connection identifier
    * `:channel` - filter by channel type
    * `:provider_id` - filter by provider identifier
    * `:integration_identifier` - filter by integration identifier
    * `:context_keys` - list of context keys (format `"type:id"`)

  [API Documentation](https://docs.novu.co/api-reference/channel-endpoints/list-all-channel-endpoints)
  """
  @spec list_channel_endpoints(opts :: Keyword.t()) :: Http.response()
  def list_channel_endpoints(opts \\ []) do
    params =
      %{}
      |> add_optional_value(:after, opts[:after])
      |> add_optional_value(:before, opts[:before])
      |> add_optional_value(:limit, opts[:limit])
      |> add_optional_value(:orderDirection, opts[:order_direction])
      |> add_optional_value(:orderBy, opts[:order_by])
      |> add_optional_value(:includeCursor, opts[:include_cursor])
      |> add_optional_value(:subscriberId, opts[:subscriber_id])
      |> add_optional_value(:connectionIdentifier, opts[:connection_identifier])
      |> add_optional_value(:channel, opts[:channel])
      |> add_optional_value(:providerId, opts[:provider_id])
      |> add_optional_value(:integrationIdentifier, opts[:integration_identifier])
      |> add_optional_value(:contextKeys, opts[:context_keys])

    Http.get("/v1/channel-endpoints", params)
  end

  @doc """
  Creates a channel endpoint.

  `attrs` is passed through as the request body. The body shape depends on the provider (Slack channel or user, webhook, phone, Webex room); see the API reference for the matching DTO.

  [API Documentation](https://docs.novu.co/api-reference/channel-endpoints/create-a-channel-endpoint)
  """
  @spec create_channel_endpoint(attrs :: map()) :: Http.response()
  def create_channel_endpoint(attrs), do: Http.post("/v1/channel-endpoints", attrs)

  @doc """
  Retrieves a channel endpoint by its identifier.

  [API Documentation](https://docs.novu.co/api-reference/channel-endpoints/retrieve-a-channel-endpoint)
  """
  @spec get_channel_endpoint(identifier :: String.t()) :: Http.response()
  def get_channel_endpoint(identifier), do: identifier |> endpoint_path() |> Http.get()

  @doc """
  Updates a channel endpoint.

  `attrs` is passed through as the request body.

  [API Documentation](https://docs.novu.co/api-reference/channel-endpoints/update-a-channel-endpoint)
  """
  @spec update_channel_endpoint(identifier :: String.t(), attrs :: map()) :: Http.response()
  def update_channel_endpoint(identifier, attrs), do: identifier |> endpoint_path() |> Http.patch(attrs)

  @doc """
  Deletes a channel endpoint.

  [API Documentation](https://docs.novu.co/api-reference/channel-endpoints/delete-a-channel-endpoint)
  """
  @spec delete_channel_endpoint(identifier :: String.t()) :: Http.response()
  def delete_channel_endpoint(identifier), do: identifier |> endpoint_path() |> Http.delete()

  defp endpoint_path(identifier), do: "/v1/channel-endpoints/#{Http.path_segment(identifier)}"

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
