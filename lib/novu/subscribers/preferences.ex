defmodule Novu.Subscribers.Preferences do
  @moduledoc """
  Provide access to the Novu Subscriber Preferences API (v2).
  """

  alias Novu.Http

  @doc """
  Retrieves the channel preferences of a subscriber for all workflows and the global preferences.

  ## Options

    * `:criticality` - `"critical"`, `"nonCritical"` or `"all"`
    * `:context_keys` - list of context keys used to filter preferences, e.g. `["tenant:acme"]`

  [API Documentation](https://docs.novu.co/api-reference/subscribers/retrieve-subscriber-preferences)
  """
  @spec get(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def get(subscriber_id, opts \\ []) do
    params =
      %{}
      |> add_optional_value(:criticality, opts[:criticality])
      |> add_optional_value(:contextKeys, opts[:context_keys])

    subscriber_id |> preferences_path() |> Http.get(params)
  end

  @doc """
  Updates the preferences of a subscriber. When `:workflow_id` is given the workflow specific
  preferences are updated, otherwise the global preferences.

  ## Options

    * `:channels` - map of channel to boolean, e.g. `%{email: true, in_app: false}`
      (keys: `email`, `sms`, `in_app`, `push`, `chat`, `tool`)
    * `:workflow_id` - workflow internal `_id`, identifier or slug
    * `:schedule` - subscriber schedule map
    * `:context` - context map

  [API Documentation](https://docs.novu.co/api-reference/subscribers/update-subscriber-preferences)
  """
  @spec update(subscriber_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update(subscriber_id, opts \\ []) do
    payload =
      %{}
      |> add_optional_value(:channels, opts[:channels])
      |> add_optional_value(:workflowId, opts[:workflow_id])
      |> add_optional_value(:schedule, opts[:schedule])
      |> add_optional_value(:context, opts[:context])

    subscriber_id |> preferences_path() |> Http.patch(payload)
  end

  @doc """
  Updates the preferences of multiple workflows in a single request (maximum 100 items).

  Each item in `preferences` must contain `workflowId` and `channels`, e.g.
  `%{workflowId: "welcome", channels: %{email: false}}`.

  ## Options

    * `:context` - context map

  [API Documentation](https://docs.novu.co/api-reference/subscribers/bulk-update-subscriber-preferences)
  """
  @spec bulk_update(subscriber_id :: String.t(), preferences :: [map()], opts :: Keyword.t()) :: Http.response()
  def bulk_update(subscriber_id, preferences, opts \\ []) when is_list(preferences) do
    payload = add_optional_value(%{preferences: preferences}, :context, opts[:context])

    Http.patch("#{preferences_path(subscriber_id)}/bulk", payload)
  end

  defp preferences_path(subscriber_id), do: "/v2/subscribers/#{Http.path_segment(subscriber_id)}/preferences"

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
