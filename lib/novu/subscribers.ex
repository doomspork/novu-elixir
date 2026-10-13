defmodule Novu.Subscribers do
  @moduledoc """
  Provide access to the Novu Subscribers API
  """

  alias Novu.Http

  @doc """
  Searches subscribers using cursor pagination and optional filters.

  The search is case sensitive.

  ## Options

    * `:after` - cursor to fetch results after
    * `:before` - cursor to fetch results before
    * `:limit` - number of items to return
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to order by
    * `:include_cursor` - include the cursor item in the response
    * `:email` - filter by email
    * `:name` - filter by name
    * `:phone` - filter by phone
    * `:subscriber_id` - filter by subscriber identifier

  [API Documentation](https://docs.novu.co/api-reference/subscribers/search-subscribers)
  """
  @spec search_subscribers(opts :: Keyword.t()) :: Http.response()
  def search_subscribers(opts \\ []) do
    params =
      %{}
      |> add_optional_value(:after, opts[:after])
      |> add_optional_value(:before, opts[:before])
      |> add_optional_value(:limit, opts[:limit])
      |> add_optional_value(:orderDirection, opts[:order_direction])
      |> add_optional_value(:orderBy, opts[:order_by])
      |> add_optional_value(:includeCursor, opts[:include_cursor])
      |> add_optional_value(:email, opts[:email])
      |> add_optional_value(:name, opts[:name])
      |> add_optional_value(:phone, opts[:phone])
      |> add_optional_value(:subscriberId, opts[:subscriber_id])

    Http.get("/v2/subscribers", params)
  end

  @doc """
  Deprecated wrapper around `search_subscribers/1`.

  Only `:limit` is forwarded. The `:page` option is no longer supported by the
  API (pagination is cursor based) and is ignored.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/search-subscribers)
  """
  @deprecated "Use search_subscribers/1"
  @spec get_subscribers(opts :: Keyword.t()) :: Http.response()
  def get_subscribers(opts \\ []) do
    search_subscribers(limit: opts[:limit])
  end

  @doc """
  Creates a subscriber entity in the Novu platform. If the subscriber already exists it is
  updated, unless `:fail_if_exists` is `true`.

  ## Options

    * `:email`, `:first_name`, `:last_name`, `:phone`, `:avatar`
    * `:locale`, `:timezone`
    * `:data` - map of custom data
    * `:fail_if_exists` - when `true`, the request fails if the subscriber already exists
      (sent as the `failIfExists` query parameter)

  [API Documentation](https://docs.novu.co/api-reference/subscribers/create-a-subscriber)
  """
  @spec create_subscriber(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def create_subscriber(subscriber_id, opts \\ []) do
    payload =
      opts
      |> Keyword.put(:subscriber_id, subscriber_id)
      |> build_subscriber_payload()

    params = add_optional_value(%{}, :failIfExists, opts[:fail_if_exists])

    Http.post("/v2/subscribers", payload, params: params)
  end

  @doc """
  Retrieves a subscriber by its unique identifier.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/retrieve-a-subscriber)
  """
  @spec get_subscriber(subscriber_id :: String.t()) :: Http.response()
  def get_subscriber(subscriber_id) do
    Http.get("/v2/subscribers/#{Http.path_segment(subscriber_id)}")
  end

  @doc """
  Updates a subscriber with new information.

  ## Options

  `:email`, `:first_name`, `:last_name`, `:phone`, `:avatar`, `:locale`, `:timezone`, `:data`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/update-a-subscriber)
  """
  @spec update_subscriber(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update_subscriber(subscriber_id, opts \\ []) do
    payload = opts |> Keyword.delete(:subscriber_id) |> build_subscriber_payload()
    Http.patch("/v2/subscribers/#{Http.path_segment(subscriber_id)}", payload)
  end

  @doc """
  Deletes a subscriber from the Novu platform along with associated messages, preferences
  and topic subscriptions.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/delete-a-subscriber)
  """
  @spec delete_subscriber(subscriber_id :: String.t()) :: Http.response()
  def delete_subscriber(subscriber_id) do
    Http.delete("/v2/subscribers/#{Http.path_segment(subscriber_id)}")
  end

  @doc """
  Creates multiple subscribers at once.

  Each item is a map shaped like the create subscriber body (`subscriberId` required;
  optional `firstName`, `lastName`, `email`, `phone`, `avatar`, `locale`, `timezone`, `data`).
  The bulk API is limited to 500 subscribers per request.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/bulk-create-subscribers)
  """
  @spec bulk_create_subscribers(subscribers :: [map()]) :: Http.response()
  def bulk_create_subscribers(subscribers) when is_list(subscribers) do
    Http.post("/v1/subscribers/bulk", %{subscribers: subscribers})
  end

  @doc """
  Updates the online status of a subscriber.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/update-subscriber-online-status)
  """
  @spec update_subscriber_online_status(subscriber_id :: String.t(), is_online :: boolean()) :: Http.response()
  def update_subscriber_online_status(subscriber_id, is_online) when is_boolean(is_online) do
    Http.patch("/v1/subscribers/#{Http.path_segment(subscriber_id)}/online-status", %{isOnline: is_online})
  end

  @doc """
  Updates subscriber credentials for a chat or push provider. Creates `deviceTokens` or
  replaces the existing ones.

  ## Options

    * `:integration_identifier` - the integration identifier
    * `:webhook_url`, `:channel`, `:device_tokens`, `:alert_uid`, `:title`, `:image_url`,
      `:state`, `:external_url` - provider credentials

  [API Documentation](https://docs.novu.co/api-reference/subscribers/update-provider-credentials)
  """
  @spec update_subscriber_credentials(subscriber_id :: String.t(), provider_id :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def update_subscriber_credentials(subscriber_id, provider_id, opts \\ []) do
    subscriber_id |> credentials_path() |> Http.put(credentials_payload(provider_id, opts))
  end

  @doc """
  Upserts subscriber credentials for a chat or push provider. Creates `deviceTokens` or
  appends to the existing ones. Accepts the same options as `update_subscriber_credentials/3`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/upsert-provider-credentials)
  """
  @spec upsert_subscriber_credentials(subscriber_id :: String.t(), provider_id :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def upsert_subscriber_credentials(subscriber_id, provider_id, opts \\ []) do
    subscriber_id |> credentials_path() |> Http.patch(credentials_payload(provider_id, opts))
  end

  @doc """
  Deletes the credentials of a provider for a subscriber. This action is irreversible.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/delete-provider-credentials)
  """
  @spec delete_subscriber_credentials(subscriber_id :: String.t(), provider_id :: String.t()) :: Http.response()
  def delete_subscriber_credentials(subscriber_id, provider_id) do
    Http.delete("#{credentials_path(subscriber_id)}/#{Http.path_segment(provider_id)}")
  end

  @doc """
  Get a subscriber's preferences.

  **Deprecated**: the v1 endpoint was removed from the Novu API; use `Novu.Subscribers.Preferences.get/2`.

  [API Documentation](https://docs.novu.co/api/get-subscriber-preference/)
  """
  @deprecated "Use Novu.Subscribers.Preferences.get/2"
  @spec get_subscriber_preferences(subscriber_id :: String.t()) :: Http.response()
  def get_subscriber_preferences(subscriber_id) do
    Http.get("/v1/subscribers/#{Http.path_segment(subscriber_id)}/preferences")
  end

  @doc """
  Update a subscriber's preference for a workflow channel.

  **Deprecated**: the v1 endpoint was removed from the Novu API; use `Novu.Subscribers.Preferences.update/2`.

  [API Documentation](https://docs.novu.co/api/update-subscriber-preferences/)
  """
  @deprecated "Use Novu.Subscribers.Preferences.update/2"
  @spec update_subscriber_preferences(
          subscriber_id :: String.t(),
          template_id :: String.t(),
          type :: String.t(),
          enabled :: boolean()
        ) :: Http.response()
  def update_subscriber_preferences(subscriber_id, template_id, type, enabled) do
    payload = %{
      channel: %{
        type: type,
        enabled: enabled
      }
    }

    Http.patch(
      "/v1/subscribers/#{Http.path_segment(subscriber_id)}/preferences/#{Http.path_segment(template_id)}",
      payload
    )
  end

  @doc """
  Get a subscriber's notification feed.

  **Deprecated**: the v1 endpoint is deprecated in the Novu API; use `Novu.Subscribers.Notifications.list/2`.

  [API Documentation](https://docs.novu.co/api/get-a-notification-feed-for-a-particular-subscriber/)
  """
  @deprecated "Use Novu.Subscribers.Notifications.list/2"
  @spec get_notification_feed(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def get_notification_feed(subscriber_id, opts \\ []) do
    page = Keyword.get(opts, :page, 0)
    feed_identifier = Keyword.get(opts, :feed_identifier)
    seen = Keyword.get(opts, :seen)

    params =
      %{page: page}
      |> add_optional_value(:feedIdentifier, feed_identifier)
      |> add_optional_value(:seen, seen)

    Http.get("/v1/subscribers/#{Http.path_segment(subscriber_id)}/notifications/feed", params)
  end

  @doc """
  Get the unseen notification count for a subscriber.

  **Deprecated**: the v1 endpoint is deprecated in the Novu API; use `Novu.Subscribers.Notifications.count/2`.

  [API Documentation](https://docs.novu.co/api/get-the-unseen-notification-count-for-subscribers-feed/)
  """
  @deprecated "Use Novu.Subscribers.Notifications.count/2"
  @spec get_unseen_count(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def get_unseen_count(subscriber_id, opts \\ []) do
    seen = Keyword.get(opts, :seen)
    params = add_optional_value(%{}, :seen, seen)

    Http.get("/v1/subscribers/#{Http.path_segment(subscriber_id)}/notifications/unseen", params)
  end

  @doc """
  Mark a subscriber's message as seen.

  **Deprecated**: the endpoint was removed from the Novu API; use `Novu.Subscribers.Notifications.mark_as_seen/2`.

  [API Documentation](https://docs.novu.co/api/mark-a-subscriber-feed-message-as-seen/)
  """
  @deprecated "Use Novu.Subscribers.Notifications.mark_as_seen/2"
  @spec mark_message_as_seen(subscriber_id :: String.t(), message_id :: String.t()) :: Http.response()
  def mark_message_as_seen(subscriber_id, message_id) do
    payload = %{
      messageId: message_id,
      subscriberId: subscriber_id
    }

    Http.post(
      "/v1/subscribers/#{Http.path_segment(subscriber_id)}/messages/#{Http.path_segment(message_id)}/seen",
      payload
    )
  end

  @doc """
  Mark a message action as seen for a subscriber.

  **Deprecated**: the v1 endpoint is deprecated in the Novu API; use `Novu.Subscribers.Notifications.complete_action/4`.

  [API Documentation](https://docs.novu.co/api/mark-a-subscriber-feed-message-as-seen/)
  """
  @deprecated "Use Novu.Subscribers.Notifications.complete_action/4"
  @spec mark_action_as_seen(subscriber_id :: String.t(), message_id :: String.t(), type :: String.t()) ::
          Http.response()
  def mark_action_as_seen(subscriber_id, message_id, type) do
    payload = %{
      messageId: message_id,
      type: type,
      subscriberId: subscriber_id
    }

    Http.post(
      "/v1/subscribers/#{Http.path_segment(subscriber_id)}/messages/#{Http.path_segment(message_id)}/actions/#{Http.path_segment(type)}",
      payload
    )
  end

  @doc """
  Retrieves the topic subscriptions of a subscriber.

  ## Options

    * `:after`, `:before` - pagination cursors
    * `:limit` - number of items to return (max 100)
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to order by
    * `:include_cursor` - include the cursor item in the response
    * `:key` - filter by topic key
    * `:context_keys` - list of context keys to filter by exactly (format `"type:id"`)

  [API Documentation](https://docs.novu.co/api-reference/subscribers/retrieve-subscriber-subscriptions)
  """
  @spec get_subscriber_subscriptions(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def get_subscriber_subscriptions(subscriber_id, opts \\ []) do
    params =
      %{}
      |> add_optional_value(:after, opts[:after])
      |> add_optional_value(:before, opts[:before])
      |> add_optional_value(:limit, opts[:limit])
      |> add_optional_value(:orderDirection, opts[:order_direction])
      |> add_optional_value(:orderBy, opts[:order_by])
      |> add_optional_value(:includeCursor, opts[:include_cursor])
      |> add_optional_value(:key, opts[:key])
      |> add_optional_value(:contextKeys, opts[:context_keys])

    Http.get("/v2/subscribers/#{Http.path_segment(subscriber_id)}/subscriptions", params)
  end

  defp credentials_path(subscriber_id), do: "/v1/subscribers/#{Http.path_segment(subscriber_id)}/credentials"

  defp credentials_payload(provider_id, opts) do
    credentials =
      %{}
      |> add_optional_value(:webhookUrl, opts[:webhook_url])
      |> add_optional_value(:channel, opts[:channel])
      |> add_optional_value(:deviceTokens, opts[:device_tokens])
      |> add_optional_value(:alertUid, opts[:alert_uid])
      |> add_optional_value(:title, opts[:title])
      |> add_optional_value(:imageUrl, opts[:image_url])
      |> add_optional_value(:state, opts[:state])
      |> add_optional_value(:externalUrl, opts[:external_url])

    add_optional_value(
      %{providerId: provider_id, credentials: credentials},
      :integrationIdentifier,
      opts[:integration_identifier]
    )
  end

  defp build_subscriber_payload(opts) do
    %{}
    |> add_optional_value(:subscriberId, opts[:subscriber_id])
    |> add_optional_value(:email, opts[:email])
    |> add_optional_value(:firstName, opts[:first_name])
    |> add_optional_value(:lastName, opts[:last_name])
    |> add_optional_value(:phone, opts[:phone])
    |> add_optional_value(:avatar, opts[:avatar])
    |> add_optional_value(:locale, opts[:locale])
    |> add_optional_value(:timezone, opts[:timezone])
    |> add_optional_value(:data, opts[:data])
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
