defmodule Novu.Events do
  @moduledoc """
  Provide access to the Novu Event API
  """

  alias Novu.Http

  @max_bulk_events 100

  @type recipient :: String.t() | map()

  @doc """
  Trigger a broadcast event to all existing subscribers, could be used to send announcements, etc.
  In the future could be used to trigger events to a subset of subscribers based on defined filters.

  ## Options

    * `:overrides` - provider specific overrides
    * `:transaction_id` - unique identifier for this transaction
    * `:actor` - subscriber id (string) or subscriber object (map) used to display the actor's avatar
    * `:tenant` - tenant identifier (string) or tenant object (map)
    * `:context` - context map
    * `:agent_id` - override the workflow-assigned agent

  [API Documentation](https://docs.novu.co/api-reference/events/broadcast-event-to-all)
  """
  @spec broadcast_to_all(name :: String.t(), payload :: map(), opts :: Keyword.t()) :: Http.response()
  def broadcast_to_all(name, payload, opts \\ []) do
    payload = build_event_payload(name, payload, nil, Keyword.delete(opts, :bridge_url))
    Http.post("/v1/events/trigger/broadcast", payload)
  end

  @doc """
  Trigger multiple events in a single request.

  Each element of `events` is a map in API shape (camelCase keys), the same body accepted by
  `trigger_event/4`. At most #{@max_bulk_events} events are allowed per request; passing more
  raises an `ArgumentError`.

  ## Example

      Novu.Events.bulk_trigger([
        %{name: "welcome", to: "subscriber-1", payload: %{name: "Ada"}},
        %{name: "digest", to: [%{subscriberId: "subscriber-2", email: "b@example.com"}], transactionId: "tx-1"}
      ])

  [API Documentation](https://docs.novu.co/api-reference/events/bulk-trigger-event)
  """
  @spec bulk_trigger(events :: [map()]) :: Http.response()
  def bulk_trigger(events) when is_list(events) and length(events) <= @max_bulk_events do
    Http.post("/v1/events/trigger/bulk", %{events: events})
  end

  def bulk_trigger(events) when is_list(events) do
    raise ArgumentError,
          "bulk_trigger/1 accepts at most #{@max_bulk_events} events, got #{length(events)}"
  end

  @doc """
  Using a previously generated transactionId during the event trigger, will cancel any active or pending workflows.

  [API Documentation](https://docs.novu.co/api-reference/events/cancel-triggered-event)
  """
  @spec cancel_event(transaction_id :: String.t()) :: Http.response()
  def cancel_event(transaction_id) do
    Http.delete("/v1/events/trigger/#{Http.path_segment(transaction_id)}")
  end

  @doc """
  Trigger event is the main (and the only) way to send notification to subscribers.
  The trigger identifier is used to match the particular workflow associated with it.

  `to` accepts (maximum of 100 recipients when a list):

    * a subscriber id string: `"subscriber-1"`
    * a subscriber object: `%{subscriberId: "subscriber-1", email: "a@example.com"}`
    * a topic object: `%{type: "Topic", topicKey: "my-topic"}`
    * a list mixing any of the above: `["subscriber-1", %{type: "Topic", topicKey: "my-topic"}]`

  ## Options

    * `:overrides` - provider specific overrides
    * `:transaction_id` - unique identifier used for deduplication
    * `:actor` - subscriber id (string) or subscriber object (map) used to display the actor's avatar
    * `:tenant` - tenant identifier (string) or tenant object (map)
    * `:context` - context map
    * `:bridge_url` - Bridge endpoint URL used to route this trigger
    * `:agent_id` - override the workflow-assigned agent

  [API Documentation](https://docs.novu.co/api-reference/events/trigger-event)
  """
  @spec trigger_event(name :: String.t(), payload :: map(), to :: recipient() | [recipient()], opts :: Keyword.t()) ::
          Http.response()
  def trigger_event(name, payload, to, opts \\ []) do
    payload = build_event_payload(name, payload, to, opts)
    Http.post("/v1/events/trigger", payload)
  end

  defp build_event_payload(name, payload, to, opts) do
    %{name: name, payload: payload}
    |> add_optional_value(:to, to)
    |> add_optional_value(:overrides, Keyword.get(opts, :overrides))
    |> add_optional_value(:transactionId, Keyword.get(opts, :transaction_id))
    |> add_optional_value(:actor, Keyword.get(opts, :actor))
    |> add_optional_value(:tenant, Keyword.get(opts, :tenant))
    |> add_optional_value(:context, Keyword.get(opts, :context))
    |> add_optional_value(:bridgeUrl, Keyword.get(opts, :bridge_url))
    |> add_optional_value(:agentId, Keyword.get(opts, :agent_id))
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
