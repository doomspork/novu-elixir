defmodule Novu.Messages do
  @moduledoc """
  Provide access to the Novu Messages API
  """

  alias Novu.Http

  @doc """
  Retrieves a paginated list of messages.

  ## Options

    * `:channel` - filter by channel type (e.g. `"email"`, `"in_app"`)
    * `:subscriber_id` - filter by subscriber ID
    * `:transaction_id` - filter by transaction ID (a string or a list of strings)
    * `:context_keys` - list of exact context keys (format `"type:id"`)
    * `:page` - page number
    * `:limit` - page size

  [API Documentation](https://docs.novu.co/api-reference/messages/list-all-messages)
  """
  @spec get_messages(opts :: keyword()) :: Http.response()
  def get_messages(opts \\ []) do
    params =
      %{}
      |> add_optional_value(:channel, opts[:channel])
      |> add_optional_value(:subscriberId, opts[:subscriber_id])
      |> add_optional_value(:transactionId, opts[:transaction_id])
      |> add_optional_value(:contextKeys, opts[:context_keys])
      |> add_optional_value(:page, opts[:page])
      |> add_optional_value(:limit, opts[:limit])

    Http.get("/v1/messages", params)
  end

  @doc """
  Deletes a message by its ID.

  [API Documentation](https://docs.novu.co/api-reference/messages/delete-a-message)
  """
  @spec delete_message(message_id :: String.t()) :: Http.response()
  def delete_message(message_id) do
    Http.delete("/v1/messages/#{Http.path_segment(message_id)}")
  end

  @doc """
  Deletes a message by its ID.

  Deprecated, use `delete_message/1`.

  [API Documentation](https://docs.novu.co/api-reference/messages/delete-a-message)
  """
  @deprecated "Use delete_message/1"
  @spec delete_messages(message_id :: String.t()) :: Http.response()
  def delete_messages(message_id), do: delete_message(message_id)

  @doc """
  Deletes all messages associated with a transaction ID.

  ## Options

    * `:channel` - only delete messages of this channel (`"in_app"`, `"email"`,
      `"sms"`, `"chat"`, `"push"` or `"tool"`)

  [API Documentation](https://docs.novu.co/api-reference/messages/delete-messages-by-transactionid)
  """
  @spec delete_messages_by_transaction_id(transaction_id :: String.t(), opts :: keyword()) ::
          Http.response()
  def delete_messages_by_transaction_id(transaction_id, opts \\ []) do
    params = add_optional_value(%{}, :channel, opts[:channel])

    Http.delete("/v1/messages/transaction/#{Http.path_segment(transaction_id)}", params: params)
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
