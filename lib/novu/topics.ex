defmodule Novu.Topics do
  @moduledoc """
  Provide access to the Novu Topics API.

  Topics are fan-out groups of subscribers. Once subscribers are attached to a
  topic you can trigger a workflow to all of them with
  `to: %{type: "Topic", topicKey: key}`.
  """

  alias Novu.Http

  @type subscription() :: String.t() | map()

  @list_params [
    after: "after",
    before: "before",
    limit: "limit",
    order_direction: "orderDirection",
    order_by: "orderBy",
    include_cursor: "includeCursor"
  ]

  @doc """
  List topics (cursor paginated).

  ## Options

    * `:after`, `:before`, `:limit`, `:order_direction`, `:order_by`, `:include_cursor` - pagination and sorting
    * `:key` - filter by topic key
    * `:name` - filter by topic name

  [API Documentation](https://docs.novu.co/api-reference/topics/list-all-topics)
  """
  @spec list_topics(opts :: Keyword.t()) :: Http.response()
  def list_topics(opts \\ []) do
    Http.get("/v2/topics", query_params(opts, @list_params ++ [key: "key", name: "name"]))
  end

  @doc """
  Create a topic. Updates the topic if it already exists unless `fail_if_exists: true` is given.

  ## Options

    * `:name` - display name of the topic
    * `:data` - custom data map attached to the topic
    * `:fail_if_exists` - when `true` the request fails if the key already exists (query `failIfExists`)

  [API Documentation](https://docs.novu.co/api-reference/topics/create-a-topic)
  """
  @spec create_topic(key :: String.t(), opts :: Keyword.t()) :: Http.response()
  def create_topic(key, opts \\ []) do
    body =
      %{key: key}
      |> add_optional_value(:name, opts[:name])
      |> add_optional_value(:data, opts[:data])

    Http.post("/v2/topics", body, params: query_params(opts, fail_if_exists: "failIfExists"))
  end

  @doc """
  Retrieve a topic by key.

  [API Documentation](https://docs.novu.co/api-reference/topics/retrieve-a-topic)
  """
  @spec get_topic(key :: String.t()) :: Http.response()
  def get_topic(key), do: key |> topic_path() |> Http.get()

  @doc """
  Update a topic.

  ## Options

    * `:name` - display name of the topic
    * `:data` - custom data map (omit to leave unchanged)

  [API Documentation](https://docs.novu.co/api-reference/topics/update-a-topic)
  """
  @spec update_topic(key :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update_topic(key, opts \\ []) do
    body =
      %{}
      |> add_optional_value(:name, opts[:name])
      |> add_optional_value(:data, opts[:data])

    key |> topic_path() |> Http.patch(body)
  end

  @doc """
  Delete a topic.

  [API Documentation](https://docs.novu.co/api-reference/topics/delete-a-topic)
  """
  @spec delete_topic(key :: String.t()) :: Http.response()
  def delete_topic(key), do: key |> topic_path() |> Http.delete()

  @doc """
  List the subscriptions of a topic (cursor paginated).

  ## Options

    * `:after`, `:before`, `:limit`, `:order_direction`, `:order_by`, `:include_cursor` - pagination and sorting
    * `:subscriber_id` - filter by subscriber id
    * `:context_keys` - list of `"type:id"` context keys to filter by (sent as repeated `contextKeys`)

  [API Documentation](https://docs.novu.co/api-reference/topics/list-topic-subscriptions)
  """
  @spec list_topic_subscriptions(key :: String.t(), opts :: Keyword.t()) :: Http.response()
  def list_topic_subscriptions(key, opts \\ []) do
    params = query_params(opts, @list_params ++ [subscriber_id: "subscriberId", context_keys: "contextKeys"])
    key |> subscriptions_path() |> Http.get(params)
  end

  @doc """
  Subscribe subscribers to a topic. The topic is created if it does not exist.

  `subscriptions` is a list of subscriber ids, or maps such as
  `%{identifier: "sub-a", subscriberId: "subscriber-123", name: "My Subscription"}`.

  ## Options

    * `:name` - name of the topic
    * `:context` - context map
    * `:preferences` - list of workflow ids or preference maps

  [API Documentation](https://docs.novu.co/api-reference/topics/create-topic-subscriptions)
  """
  @spec create_topic_subscriptions(key :: String.t(), subscriptions :: [subscription()], opts :: Keyword.t()) ::
          Http.response()
  def create_topic_subscriptions(key, subscriptions, opts \\ []) do
    body =
      %{subscriptions: subscriptions}
      |> add_optional_value(:name, opts[:name])
      |> add_optional_value(:context, opts[:context])
      |> add_optional_value(:preferences, opts[:preferences])

    key |> subscriptions_path() |> Http.post(body)
  end

  @doc """
  Unsubscribe subscribers from a topic.

  `subscriptions` is a list of subscriber ids, or maps with `identifier` and/or `subscriberId`.

  [API Documentation](https://docs.novu.co/api-reference/topics/delete-topic-subscriptions)
  """
  @spec delete_topic_subscriptions(key :: String.t(), subscriptions :: [subscription()]) :: Http.response()
  def delete_topic_subscriptions(key, subscriptions) do
    key |> subscriptions_path() |> Http.delete(json: %{subscriptions: subscriptions})
  end

  @doc """
  Retrieve a single topic subscription by its identifier.

  [API Documentation](https://docs.novu.co/api-reference/topics/retrieve-a-topic-subscription)
  """
  @spec get_topic_subscription(key :: String.t(), identifier :: String.t()) :: Http.response()
  def get_topic_subscription(key, identifier), do: key |> subscription_path(identifier) |> Http.get()

  @doc """
  Update a topic subscription.

  ## Options

    * `:name` - name of the subscription
    * `:preferences` - list of workflow ids or preference maps

  [API Documentation](https://docs.novu.co/api-reference/topics/update-a-topic-subscription)
  """
  @spec update_topic_subscription(key :: String.t(), identifier :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def update_topic_subscription(key, identifier, opts \\ []) do
    body =
      %{}
      |> add_optional_value(:name, opts[:name])
      |> add_optional_value(:preferences, opts[:preferences])

    key |> subscription_path(identifier) |> Http.patch(body)
  end

  @doc """
  Check whether a subscriber belongs to a topic.

  [API Documentation](https://docs.novu.co/api-reference/topics/check-topic-subscriber)
  """
  @spec check_topic_subscriber(key :: String.t(), subscriber_id :: String.t()) :: Http.response()
  def check_topic_subscriber(key, subscriber_id) do
    Http.get("/v1/topics/#{Http.path_segment(key)}/subscribers/#{Http.path_segment(subscriber_id)}")
  end

  defp topic_path(key), do: "/v2/topics/#{Http.path_segment(key)}"
  defp subscriptions_path(key), do: topic_path(key) <> "/subscriptions"
  defp subscription_path(key, identifier), do: subscriptions_path(key) <> "/#{Http.path_segment(identifier)}"

  defp query_params(opts, names) do
    for {opt, name} <- names, (value = opts[opt]) != nil, into: %{}, do: {name, value}
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
