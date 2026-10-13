defmodule Novu.Integrations do
  @moduledoc """
  Provide access to the Novu Integrations API (`/v1/integrations`).

  Functions that take `attrs` accept a plain map in the API's camelCase shape
  and pass it through unchanged. The deprecated `POST /v1/integrations/chat/oauth`
  endpoint is intentionally not supported.
  """

  alias Novu.Http

  @doc """
  Lists all the channel integrations created in the organization.

  [API Documentation](https://docs.novu.co/api-reference/integrations/list-all-integrations)
  """
  @spec list_integrations() :: Http.response()
  def list_integrations, do: Http.get("/v1/integrations")

  @doc """
  Lists all the active integrations created in the organization.

  [API Documentation](https://docs.novu.co/api-reference/integrations/list-active-integrations)
  """
  @spec list_active_integrations() :: Http.response()
  def list_active_integrations, do: Http.get("/v1/integrations/active")

  @doc """
  Creates an integration for the current environment.

  `channel` is one of `"in_app"`, `"email"`, `"sms"`, `"chat"` or `"push"`.
  `credentials` keys are provider specific and passed through as a map.

  ## Options

    * `:name` - the name of the integration
    * `:identifier` - the unique identifier for the integration
    * `:environment_id` - the ID of the associated environment (sent as `_environmentId`)
    * `:kind` - `"delivery"` or `"agent"`
    * `:credentials` - map of provider specific credentials
    * `:active` - whether the integration is active
    * `:check` - whether to check the integration status
    * `:conditions` - legacy step filter conditions
    * `:rules` - JSONLogic rules used to select this integration at send time
    * `:configurations` - map of integration configurations

  [API Documentation](https://docs.novu.co/api-reference/integrations/create-an-integration)
  """
  @spec create_integration(provider_id :: String.t(), channel :: String.t(), opts :: Keyword.t()) ::
          Http.response()
  def create_integration(provider_id, channel, opts \\ []) do
    body =
      %{providerId: provider_id, channel: channel}
      |> add_optional_value(:kind, opts[:kind])
      |> add_integration_options(opts)

    Http.post("/v1/integrations", body)
  end

  @doc """
  Updates an integration.

  ## Options

    * `:name` - the name of the integration
    * `:identifier` - the unique identifier for the integration
    * `:environment_id` - the ID of the associated environment (sent as `_environmentId`)
    * `:credentials` - map of provider specific credentials
    * `:active` - whether the integration is active
    * `:check` - whether to check the integration status
    * `:conditions` - legacy step filter conditions
    * `:rules` - JSONLogic rules used to select this integration at send time
    * `:configurations` - map of integration configurations

  [API Documentation](https://docs.novu.co/api-reference/integrations/update-an-integration)
  """
  @spec update_integration(integration_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update_integration(integration_id, opts \\ []) do
    body = add_integration_options(%{}, opts)

    integration_id |> integration_path() |> Http.put(body)
  end

  @doc """
  Deletes an integration. This action is irreversible.

  [API Documentation](https://docs.novu.co/api-reference/integrations/delete-an-integration)
  """
  @spec delete_integration(integration_id :: String.t()) :: Http.response()
  def delete_integration(integration_id), do: integration_id |> integration_path() |> Http.delete()

  @doc """
  Sets an integration as the primary one for its channel in the current environment.

  [API Documentation](https://docs.novu.co/api-reference/integrations/update-integration-as-primary)
  """
  @spec set_integration_as_primary(integration_id :: String.t()) :: Http.response()
  def set_integration_as_primary(integration_id) do
    Http.post(integration_path(integration_id) <> "/set-primary", nil)
  end

  @doc """
  Auto-configures an integration for inbound webhooks.

  [API Documentation](https://docs.novu.co/api-reference/integrations/auto-configure-an-integration-for-inbound-webhooks)
  """
  @spec auto_configure_integration(integration_id :: String.t()) :: Http.response()
  def auto_configure_integration(integration_id) do
    Http.post(integration_path(integration_id) <> "/auto-configure", nil)
  end

  @doc """
  Registers the Novu webhook URL with the chat provider for the integration.

  `attrs` is passed through as the request body (may be an empty map).

  [API Documentation](https://docs.novu.co/api-reference/integrations/configure-a-chat-integration-webhook)
  """
  @spec configure_integration_webhook(integration_identifier :: String.t(), attrs :: map()) ::
          Http.response()
  def configure_integration_webhook(integration_identifier, attrs \\ %{}) do
    Http.post(integration_path(integration_identifier) <> "/webhook/configure", attrs)
  end

  @doc """
  Issues a short-lived mobile setup link for an existing integration.

  `attrs` is passed through as the request body. Optional key: `subscriberId`.

  [API Documentation](https://docs.novu.co/api-reference/integrations/issue-a-short-lived-mobile-setup-link-for-an-existing-integration)
  """
  @spec create_mobile_link(integration_identifier :: String.t(), attrs :: map()) :: Http.response()
  def create_mobile_link(integration_identifier, attrs \\ %{}) do
    Http.post(integration_path(integration_identifier) <> "/mobile-link", attrs)
  end

  @doc """
  Generates an OAuth URL that creates a workspace or tenant level channel connection.

  `attrs` is passed through as the request body. Required key:
  `integrationIdentifier`. Optional: `subscriberId`, `connectionIdentifier`,
  `context`, `contextHash`, `scope`, `connectionMode` and `autoLinkUser`.

  [API Documentation](https://docs.novu.co/api-reference/integrations/generate-oauth-url-for-a-workspacetenant-connection)
  """
  @spec generate_channel_connection_oauth_url(attrs :: map()) :: Http.response()
  def generate_channel_connection_oauth_url(attrs) do
    Http.post("/v1/integrations/channel-connections/oauth", attrs)
  end

  @doc """
  Generates an OAuth URL that links a subscriber to their chat identity.

  `attrs` is passed through as the request body. Required keys: `subscriberId`
  and `integrationIdentifier`. Optional: `connectionIdentifier`, `context`,
  `contextHash` and `userScope`.

  [API Documentation](https://docs.novu.co/api-reference/integrations/generate-oauth-url-to-link-a-subscriber-user-identity)
  """
  @spec generate_channel_endpoint_oauth_url(attrs :: map()) :: Http.response()
  def generate_channel_endpoint_oauth_url(attrs) do
    Http.post("/v1/integrations/channel-endpoints/oauth", attrs)
  end

  @doc """
  Issues a URL a subscriber opens to link their chat identity.

  `attrs` is passed through as the request body. Required keys:
  `integrationIdentifier` and `subscriberId`. Optional: `context` and `contextHash`.

  [API Documentation](https://docs.novu.co/api-reference/integrations/issue-a-url-to-link-a-subscriber-chat-identity)
  """
  @spec create_channel_endpoint_link(attrs :: map()) :: Http.response()
  def create_channel_endpoint_link(attrs) do
    Http.post("/v1/integrations/channel-endpoints/link", attrs)
  end

  defp integration_path(id), do: "/v1/integrations/#{Http.path_segment(id)}"

  defp add_integration_options(body, opts) do
    body
    |> add_optional_value(:name, opts[:name])
    |> add_optional_value(:identifier, opts[:identifier])
    |> add_optional_value(:_environmentId, opts[:environment_id])
    |> add_optional_value(:credentials, opts[:credentials])
    |> add_optional_value(:active, opts[:active])
    |> add_optional_value(:check, opts[:check])
    |> add_optional_value(:conditions, opts[:conditions])
    |> add_optional_value(:rules, opts[:rules])
    |> add_optional_value(:configurations, opts[:configurations])
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
