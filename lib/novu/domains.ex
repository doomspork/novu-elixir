defmodule Novu.Domains do
  @moduledoc """
  Provide access to the Novu inbound Domains & Routes API (`/v1/domains`).

  Inbound-email domains receive mail on behalf of an environment, and routes
  forward mail addressed to `<address>@<domain>` to a webhook or an agent.
  """

  alias Novu.Http

  @doc """
  Lists the inbound-email domains of the current environment.

  ## Options

    * `:after` - cursor to start after
    * `:before` - cursor to end before
    * `:limit` - number of items to return
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to order by
    * `:include_cursor` - include the cursor item in the response
    * `:name` - filter by domain name

  [API Documentation](https://docs.novu.co/api-reference/domains/list-domains-for-an-environment)
  """
  @spec list_domains(opts :: Keyword.t()) :: Http.response()
  def list_domains(opts \\ []) do
    params =
      opts
      |> pagination_params()
      |> add_optional_value(:name, opts[:name])

    Http.get("/v1/domains", params)
  end

  @doc """
  Registers a new inbound-email domain.

  ## Options

    * `:data` - map of string key-value metadata

  [API Documentation](https://docs.novu.co/api-reference/domains/create-a-domain)
  """
  @spec create_domain(name :: String.t(), opts :: Keyword.t()) :: Http.response()
  def create_domain(name, opts \\ []) do
    body = add_optional_value(%{name: name}, :data, opts[:data])

    Http.post("/v1/domains", body)
  end

  @doc """
  Retrieves a domain by name.

  [API Documentation](https://docs.novu.co/api-reference/domains/retrieve-a-domain-by-name)
  """
  @spec get_domain(domain :: String.t()) :: Http.response()
  def get_domain(domain), do: domain |> domain_path() |> Http.get()

  @doc """
  Updates a domain.

  ## Options

    * `:data` - map of metadata; replaces the whole metadata object when given

  [API Documentation](https://docs.novu.co/api-reference/domains/update-a-domain)
  """
  @spec update_domain(domain :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update_domain(domain, opts \\ []) do
    body = add_optional_value(%{}, :data, opts[:data])

    domain |> domain_path() |> Http.patch(body)
  end

  @doc """
  Deletes a domain and all of its routes.

  [API Documentation](https://docs.novu.co/api-reference/domains/delete-a-domain)
  """
  @spec delete_domain(domain :: String.t()) :: Http.response()
  def delete_domain(domain), do: domain |> domain_path() |> Http.delete()

  @doc """
  Performs a live DNS lookup to refresh the verification status of a domain.

  [API Documentation](https://docs.novu.co/api-reference/domains/verify-a-domain)
  """
  @spec verify_domain(domain :: String.t()) :: Http.response()
  def verify_domain(domain), do: Http.post(domain_path(domain) <> "/verify", nil)

  @doc """
  Runs live DNS checks for inbound email readiness of a domain.

  [API Documentation](https://docs.novu.co/api-reference/domains/diagnose-inbound-dns-for-a-domain)
  """
  @spec diagnose_domain(domain :: String.t()) :: Http.response()
  def diagnose_domain(domain), do: Http.post(domain_path(domain) <> "/diagnose", nil)

  @doc """
  Retrieves whether DNS auto-configuration is available for a domain.

  [API Documentation](https://docs.novu.co/api-reference/domains/retrieve-auto-configuration-availability)
  """
  @spec get_domain_auto_configure(domain :: String.t()) :: Http.response()
  def get_domain_auto_configure(domain), do: Http.get(domain_path(domain) <> "/auto-configure")

  @doc """
  Starts DNS auto-configuration, returning a signed redirect URL.

  ## Options

    * `:redirect_uri` - dashboard URL to return to after the consent flow

  [API Documentation](https://docs.novu.co/api-reference/domains/start-dns-auto-configuration)
  """
  @spec start_domain_auto_configure(domain :: String.t(), opts :: Keyword.t()) :: Http.response()
  def start_domain_auto_configure(domain, opts \\ []) do
    body = add_optional_value(%{}, :redirectUri, opts[:redirect_uri])

    Http.post(domain_path(domain) <> "/auto-configure/start", body)
  end

  @doc """
  Lists the routes attached to a domain.

  ## Options

    * `:after` - cursor to start after
    * `:before` - cursor to end before
    * `:limit` - number of items to return
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to order by
    * `:include_cursor` - include the cursor item in the response
    * `:agent_id` - only routes pointing to this agent identifier

  [API Documentation](https://docs.novu.co/api-reference/domains/list-routes-for-a-domain)
  """
  @spec list_domain_routes(domain :: String.t(), opts :: Keyword.t()) :: Http.response()
  def list_domain_routes(domain, opts \\ []) do
    params =
      opts
      |> pagination_params()
      |> add_optional_value(:agentId, opts[:agent_id])

    Http.get(domain_path(domain) <> "/routes", params)
  end

  @doc """
  Creates a route forwarding mail for `<address>@<domain>`.

  `address` is the email local part (e.g. `"support"` or `"*"`).

  ## Options

    * `:type` - `"agent"` or `"webhook"` (required by the API)
    * `:agent_id` - agent identifier; required when type is `"agent"`
    * `:data` - map of string key-value metadata

  [API Documentation](https://docs.novu.co/api-reference/domains/create-a-route)
  """
  @spec create_domain_route(domain :: String.t(), address :: String.t(), opts :: Keyword.t()) :: Http.response()
  def create_domain_route(domain, address, opts \\ []) do
    body =
      %{address: address}
      |> add_optional_value(:type, opts[:type])
      |> add_optional_value(:agentId, opts[:agent_id])
      |> add_optional_value(:data, opts[:data])

    Http.post(domain_path(domain) <> "/routes", body)
  end

  @doc """
  Retrieves the route bound to `<address>@<domain>`.

  [API Documentation](https://docs.novu.co/api-reference/domains/retrieve-a-route-by-address)
  """
  @spec get_domain_route(domain :: String.t(), address :: String.t()) :: Http.response()
  def get_domain_route(domain, address), do: domain |> route_path(address) |> Http.get()

  @doc """
  Updates the route bound to `<address>@<domain>`.

  ## Options

    * `:type` - `"agent"` or `"webhook"`
    * `:agent_id` - agent identifier
    * `:data` - map of metadata; replaces route metadata when given

  [API Documentation](https://docs.novu.co/api-reference/domains/update-a-route)
  """
  @spec update_domain_route(domain :: String.t(), address :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update_domain_route(domain, address, opts \\ []) do
    body =
      %{}
      |> add_optional_value(:type, opts[:type])
      |> add_optional_value(:agentId, opts[:agent_id])
      |> add_optional_value(:data, opts[:data])

    domain |> route_path(address) |> Http.patch(body)
  end

  @doc """
  Deletes the route bound to `<address>@<domain>`.

  [API Documentation](https://docs.novu.co/api-reference/domains/delete-a-route)
  """
  @spec delete_domain_route(domain :: String.t(), address :: String.t()) :: Http.response()
  def delete_domain_route(domain, address), do: domain |> route_path(address) |> Http.delete()

  @doc """
  Sends a synthetic inbound email through a route.

  ## Options

    * `:from` - map with `"address"` (required by the API) and optional `"name"`
    * `:subject` - email subject (required by the API)
    * `:text` - plain text body
    * `:html` - HTML body
    * `:dry_run` - when `true`, returns the payload without delivering it

  [API Documentation](https://docs.novu.co/api-reference/domains/test-an-inbound-route)
  """
  @spec test_domain_route(domain :: String.t(), address :: String.t(), opts :: Keyword.t()) :: Http.response()
  def test_domain_route(domain, address, opts \\ []) do
    body =
      %{}
      |> add_optional_value(:from, opts[:from])
      |> add_optional_value(:subject, opts[:subject])
      |> add_optional_value(:text, opts[:text])
      |> add_optional_value(:html, opts[:html])
      |> add_optional_value(:dryRun, opts[:dry_run])

    Http.post(route_path(domain, address) <> "/test", body)
  end

  defp domain_path(domain), do: "/v1/domains/#{Http.path_segment(domain)}"

  defp route_path(domain, address), do: "#{domain_path(domain)}/routes/#{Http.path_segment(address)}"

  defp pagination_params(opts) do
    %{}
    |> add_optional_value(:after, opts[:after])
    |> add_optional_value(:before, opts[:before])
    |> add_optional_value(:limit, opts[:limit])
    |> add_optional_value(:orderDirection, opts[:order_direction])
    |> add_optional_value(:orderBy, opts[:order_by])
    |> add_optional_value(:includeCursor, opts[:include_cursor])
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
