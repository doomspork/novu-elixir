defmodule Novu.Subscribers.Notifications do
  @moduledoc """
  Provide access to the Novu v2 subscriber notifications (Inbox) API.

  These functions are the server-side equivalent of the actions an end user
  performs in Novu's Inbox: listing notifications, marking them as read, seen or
  unread, archiving, snoozing, deleting and completing notification actions on
  behalf of a subscriber.

  Several functions accept a `:data` option, which may be a map (it is
  JSON-encoded) or an already encoded JSON string, and a `:context_keys` option,
  which is a list of strings.
  """

  alias Novu.Http

  @type action_type() :: String.t()

  @doc """
  Retrieves the in-app (inbox) notifications of a subscriber.

  ## Options

    * `:limit` - maximum number of notifications to return
    * `:after` - cursor to paginate after
    * `:offset` - number of notifications to skip
    * `:read` - filter by read state
    * `:archived` - filter by archived state
    * `:snoozed` - filter by snoozed state
    * `:seen` - filter by seen state
    * `:data` - filter by data attributes, a map (JSON-encoded) or JSON string
    * `:severity` - list of severities (`"high"`, `"medium"`, `"low"`, `"none"`)
    * `:created_gte` - created on or after this Unix timestamp in milliseconds
    * `:created_lte` - created on or before this Unix timestamp in milliseconds
    * `:context_keys` - list of context keys

  [API Documentation](https://docs.novu.co/api-reference/subscribers/retrieve-subscriber-notifications)
  """
  @spec list(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def list(subscriber_id, opts \\ []) do
    params =
      %{}
      |> add_optional_value(:limit, opts[:limit])
      |> add_optional_value(:after, opts[:after])
      |> add_optional_value(:offset, opts[:offset])
      |> add_optional_value(:read, opts[:read])
      |> add_optional_value(:archived, opts[:archived])
      |> add_optional_value(:snoozed, opts[:snoozed])
      |> add_optional_value(:seen, opts[:seen])
      |> add_optional_value(:data, encode_json(opts[:data]))
      |> add_optional_value(:severity, opts[:severity])
      |> add_optional_value(:createdGte, opts[:created_gte])
      |> add_optional_value(:createdLte, opts[:created_lte])
      |> add_optional_value(:contextKeys, opts[:context_keys])

    subscriber_id |> base_path() |> Http.get(params)
  end

  @doc """
  Retrieves counts of a subscriber's in-app (inbox) notifications.

  `filters` is a list of filter maps (at most 30), which is JSON-encoded into the
  required `filters` query parameter.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/retrieve-subscriber-notifications-count)
  """
  @spec count(subscriber_id :: String.t(), filters :: [map()]) :: Http.response()
  def count(subscriber_id, filters) when is_list(filters) do
    Http.get(base_path(subscriber_id) <> "/count", %{filters: Jason.encode!(filters)})
  end

  @doc """
  Marks all notifications matching the filters as read.

  ## Options

    * `:tags` - filter by workflow tags
    * `:data` - filter by data attributes, a map (JSON-encoded) or JSON string
    * `:context_keys` - list of context keys

  [API Documentation](https://docs.novu.co/api-reference/subscribers/mark-all-notifications-as-read)
  """
  @spec mark_all_as_read(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def mark_all_as_read(subscriber_id, opts \\ []) do
    Http.post(base_path(subscriber_id) <> "/read", bulk_payload(opts))
  end

  @doc """
  Marks notifications as seen.

  ## Options

    * `:notification_ids` - list of specific notification ids
    * `:tags` - filter by workflow tags
    * `:data` - filter by data attributes, a map (JSON-encoded) or JSON string
    * `:context_keys` - list of context keys

  [API Documentation](https://docs.novu.co/api-reference/subscribers/mark-notifications-as-seen)
  """
  @spec mark_as_seen(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def mark_as_seen(subscriber_id, opts \\ []) do
    payload = opts |> bulk_payload() |> add_optional_value(:notificationIds, opts[:notification_ids])
    Http.post(base_path(subscriber_id) <> "/seen", payload)
  end

  @doc """
  Archives all notifications matching the filters.

  Accepts the same options as `mark_all_as_read/2`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/archive-all-notifications)
  """
  @spec archive_all(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def archive_all(subscriber_id, opts \\ []) do
    Http.post(base_path(subscriber_id) <> "/archive", bulk_payload(opts))
  end

  @doc """
  Archives all read notifications matching the filters.

  Accepts the same options as `mark_all_as_read/2`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/archive-all-read-notifications)
  """
  @spec archive_all_read(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def archive_all_read(subscriber_id, opts \\ []) do
    Http.post(base_path(subscriber_id) <> "/read-archive", bulk_payload(opts))
  end

  @doc """
  Permanently deletes all notifications matching the filters.

  Accepts the same options as `mark_all_as_read/2`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/delete-all-notifications)
  """
  @spec delete_all(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def delete_all(subscriber_id, opts \\ []) do
    Http.post(base_path(subscriber_id) <> "/delete", bulk_payload(opts))
  end

  @doc """
  Permanently deletes a single notification.

  ## Options

    * `:context_keys` - list of context keys

  [API Documentation](https://docs.novu.co/api-reference/subscribers/delete-a-notification)
  """
  @spec delete(subscriber_id :: String.t(), notification_id :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def delete(subscriber_id, notification_id, opts \\ []) do
    subscriber_id |> notification_path(notification_id) |> Http.delete(params: context_params(opts))
  end

  @doc """
  Marks a notification as read.

  ## Options

    * `:context_keys` - list of context keys

  [API Documentation](https://docs.novu.co/api-reference/subscribers/mark-a-notification-as-read)
  """
  @spec mark_as_read(subscriber_id :: String.t(), notification_id :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def mark_as_read(subscriber_id, notification_id, opts \\ []) do
    patch_state(subscriber_id, notification_id, "read", opts)
  end

  @doc """
  Marks a notification as unread.

  Accepts the same options as `mark_as_read/3`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/mark-a-notification-as-unread)
  """
  @spec mark_as_unread(subscriber_id :: String.t(), notification_id :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def mark_as_unread(subscriber_id, notification_id, opts \\ []) do
    patch_state(subscriber_id, notification_id, "unread", opts)
  end

  @doc """
  Archives a notification.

  Accepts the same options as `mark_as_read/3`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/archive-a-notification)
  """
  @spec archive(subscriber_id :: String.t(), notification_id :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def archive(subscriber_id, notification_id, opts \\ []) do
    patch_state(subscriber_id, notification_id, "archive", opts)
  end

  @doc """
  Unarchives a notification.

  Accepts the same options as `mark_as_read/3`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/unarchive-a-notification)
  """
  @spec unarchive(subscriber_id :: String.t(), notification_id :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def unarchive(subscriber_id, notification_id, opts \\ []) do
    patch_state(subscriber_id, notification_id, "unarchive", opts)
  end

  @doc """
  Unsnoozes a notification.

  Accepts the same options as `mark_as_read/3`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/unsnooze-a-notification)
  """
  @spec unsnooze(subscriber_id :: String.t(), notification_id :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def unsnooze(subscriber_id, notification_id, opts \\ []) do
    patch_state(subscriber_id, notification_id, "unsnooze", opts)
  end

  @doc """
  Snoozes a notification until the given time.

  `snooze_until` is an ISO 8601 string or a `DateTime`.

  ## Options

    * `:context_keys` - list of context keys

  [API Documentation](https://docs.novu.co/api-reference/subscribers/snooze-a-notification)
  """
  @spec snooze(
          subscriber_id :: String.t(),
          notification_id :: String.t(),
          snooze_until :: String.t() | DateTime.t(),
          opts :: Keyword.t()
        ) :: Http.response()
  def snooze(subscriber_id, notification_id, snooze_until, opts \\ []) do
    Http.patch(
      notification_path(subscriber_id, notification_id) <> "/snooze",
      %{snoozeUntil: encode_datetime(snooze_until)},
      params: context_params(opts)
    )
  end

  @doc """
  Marks a notification action as completed.

  `action_type` is `"primary"` or `"secondary"`.

  ## Options

    * `:context_keys` - list of context keys

  [API Documentation](https://docs.novu.co/api-reference/subscribers/complete-a-notification-action)
  """
  @spec complete_action(
          subscriber_id :: String.t(),
          notification_id :: String.t(),
          action_type :: action_type(),
          opts :: Keyword.t()
        ) :: Http.response()
  def complete_action(subscriber_id, notification_id, action_type, opts \\ []) do
    patch_action(subscriber_id, notification_id, action_type, "complete", opts)
  end

  @doc """
  Reverts a notification action to the pending state.

  `action_type` is `"primary"` or `"secondary"`. Accepts the same options as
  `complete_action/4`.

  [API Documentation](https://docs.novu.co/api-reference/subscribers/revert-a-notification-action)
  """
  @spec revert_action(
          subscriber_id :: String.t(),
          notification_id :: String.t(),
          action_type :: action_type(),
          opts :: Keyword.t()
        ) :: Http.response()
  def revert_action(subscriber_id, notification_id, action_type, opts \\ []) do
    patch_action(subscriber_id, notification_id, action_type, "revert", opts)
  end

  defp patch_state(subscriber_id, notification_id, state, opts) do
    Http.patch(notification_path(subscriber_id, notification_id) <> "/" <> state, nil, params: context_params(opts))
  end

  defp patch_action(subscriber_id, notification_id, action_type, verb, opts) do
    path =
      notification_path(subscriber_id, notification_id) <>
        "/actions/#{Http.path_segment(action_type)}/#{verb}"

    Http.patch(path, nil, params: context_params(opts))
  end

  defp base_path(subscriber_id), do: "/v2/subscribers/#{Http.path_segment(subscriber_id)}/notifications"

  defp notification_path(subscriber_id, notification_id),
    do: base_path(subscriber_id) <> "/#{Http.path_segment(notification_id)}"

  defp context_params(opts), do: add_optional_value(%{}, :contextKeys, opts[:context_keys])

  defp bulk_payload(opts) do
    %{}
    |> add_optional_value(:tags, opts[:tags])
    |> add_optional_value(:data, encode_json(opts[:data]))
    |> add_optional_value(:contextKeys, opts[:context_keys])
  end

  defp encode_json(nil), do: nil
  defp encode_json(value) when is_binary(value), do: value
  defp encode_json(value), do: Jason.encode!(value)

  defp encode_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp encode_datetime(value), do: value

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
