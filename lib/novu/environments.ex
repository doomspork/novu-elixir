defmodule Novu.Environments do
  @moduledoc """
  Provide access to the Novu Environments API
  """

  alias Novu.Http

  @doc """
  Retrieve the current environment

  **Deprecated**: the endpoint was removed from the Novu API; use `get_environments/0`.

  [API Documentation](https://docs.novu.co/api-reference/environments/get-current-environment)
  """
  @deprecated "The /v1/environments/me endpoint was removed from the Novu API; use get_environments/0"
  @spec get_current_environment :: Http.response()
  def get_current_environment do
    Http.get("/v1/environments/me")
  end

  @doc """
  Create a new environment using its name and a hex color. Optionally set the parent of the environment to create.

  ## Options

    * `:parent_id` - ID of the parent environment

  [API Documentation](https://docs.novu.co/api-reference/environments/create-an-environment)
  """
  @spec create_environment(name :: String.t(), color :: String.t(), opts :: Keyword.t()) :: Http.response()
  def create_environment(name, color, opts \\ []) do
    payload = add_optional_value(%{name: name, color: color}, :parentId, Keyword.get(opts, :parent_id))

    Http.post("/v1/environments", payload)
  end

  @doc """
  Delete an environment by its ID. This action is irreversible.

  [API Documentation](https://docs.novu.co/api-reference/environments/delete-an-environment)
  """
  @spec delete_environment(environment_id :: String.t()) :: Http.response()
  def delete_environment(environment_id) do
    Http.delete("/v1/environments/#{Http.path_segment(environment_id)}")
  end

  @doc """
  Compare workflows and other resources between a source and the target environment.

  ## Options

    * `:source_environment_id` - environment to compare from (defaults to the Development environment)

  [API Documentation](https://docs.novu.co/api-reference/environments/compare-resources-between-environments)
  """
  @spec diff_environment(target_environment_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def diff_environment(target_environment_id, opts \\ []) do
    payload = add_optional_value(%{}, :sourceEnvironmentId, Keyword.get(opts, :source_environment_id))
    Http.post("/v2/environments/#{Http.path_segment(target_environment_id)}/diff", payload)
  end

  @doc """
  Returns a list of environments

  [API Documentation](https://docs.novu.co/api-reference/environments/list-all-environments)
  """
  @spec get_environments :: Http.response()
  def get_environments do
    Http.get("/v1/environments")
  end

  @doc """
  List all unique workflow tags used within the environment.

  [API Documentation](https://docs.novu.co/api-reference/environments/list-environment-tags)
  """
  @spec get_environment_tags(environment_id :: String.t()) :: Http.response()
  def get_environment_tags(environment_id) do
    Http.get("/v2/environments/#{Http.path_segment(environment_id)}/tags")
  end

  @doc """
  Publish resources from a source environment to the target environment.

  ## Options

    * `:source_environment_id` - environment to sync from (defaults to the Development environment)
    * `:dry_run` - when `true`, preview the changes without applying them
    * `:resources` - list of specific resources to publish, each a map like
      `%{resourceType: "REGULAR", resourceId: "workflow-id"}` (`resourceType` is one of
      `"REGULAR"`, `"ECHO"` or `"BRIDGE"`). Publishes everything when omitted.

  [API Documentation](https://docs.novu.co/api-reference/environments/publish-resources-to-target-environment)
  """
  @spec publish_environment(target_environment_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def publish_environment(target_environment_id, opts \\ []) do
    payload =
      %{}
      |> add_optional_value(:sourceEnvironmentId, Keyword.get(opts, :source_environment_id))
      |> add_optional_value(:dryRun, Keyword.get(opts, :dry_run))
      |> add_optional_value(:resources, Keyword.get(opts, :resources))

    Http.post("/v2/environments/#{Http.path_segment(target_environment_id)}/publish", payload)
  end

  @doc """
  Update the environment entity with new information

  ## Options

    * `:name`, `:identifier`, `:parent_id`, `:color`
    * `:inbound_parse_domain` - sent as `dns.inboundParseDomain`; `dns` is omitted when not given
    * `:bridge` - bridge configuration map, e.g. `%{url: "https://example.com/api/novu"}`

  [API Documentation](https://docs.novu.co/api-reference/environments/update-an-environment)
  """
  @spec update_environment(environment_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update_environment(environment_id, opts \\ []) do
    dns = add_optional_value(%{}, :inboundParseDomain, Keyword.get(opts, :inbound_parse_domain))

    payload =
      %{}
      |> add_optional_value(:name, Keyword.get(opts, :name))
      |> add_optional_value(:identifier, Keyword.get(opts, :identifier))
      |> add_optional_value(:parentId, Keyword.get(opts, :parent_id))
      |> add_optional_value(:color, Keyword.get(opts, :color))
      |> add_optional_value(:bridge, Keyword.get(opts, :bridge))
      |> add_optional_value(:dns, if(dns == %{}, do: nil, else: dns))

    Http.put("/v1/environments/#{Http.path_segment(environment_id)}", payload)
  end

  @doc """
  Returns a list of API keys

  **Deprecated**: the endpoint was removed from the Novu API and has no replacement (manage API keys in the dashboard).

  [API Documentation](https://docs.novu.co/api-reference/environments/get-api-keys)
  """
  @deprecated "The API keys endpoints were removed from the Novu API; manage keys in the dashboard"
  @spec get_api_keys :: Http.response()
  def get_api_keys do
    Http.get("/v1/environments/api-keys")
  end

  @doc """
  Regenerate API keys

  **Deprecated**: the endpoint was removed from the Novu API and has no replacement (manage API keys in the dashboard).

  [API Documentation](https://docs.novu.co/api-reference/environments/regenerate-api-keys)
  """
  @deprecated "The API keys endpoints were removed from the Novu API; manage keys in the dashboard"
  @spec regenerate_api_keys :: Http.response()
  def regenerate_api_keys do
    Http.post("/v1/environments/api-keys/regenerate", %{})
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
