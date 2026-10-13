defmodule Novu.EnvironmentVariables do
  @moduledoc """
  Provide access to the Novu Environment Variables API (`/v1/environment-variables`).

  Secret values are masked by the API in responses.
  """

  alias Novu.Http

  @doc """
  Lists all environment variables for the current organization.

  ## Options

    * `:search` - filter variables by key (case-insensitive partial match)

  [API Documentation](https://docs.novu.co/api-reference/environment-variables/list-all-variables)
  """
  @spec list_environment_variables(opts :: Keyword.t()) :: Http.response()
  def list_environment_variables(opts \\ []) do
    params = add_optional_value(%{}, :search, opts[:search])

    Http.get("/v1/environment-variables", params)
  end

  @doc """
  Creates a new environment variable.

  Keys must be uppercase with underscores only (e.g. `BASE_URL`).

  ## Options

    * `:type` - the type of the variable
    * `:is_secret` - whether the variable is a secret (encrypted at rest, masked in responses)
    * `:values` - list of per-environment values, each a map such as
      `%{"_environmentId" => "env-id", "value" => "https://example.com"}`

  [API Documentation](https://docs.novu.co/api-reference/environment-variables/create-a-variable)
  """
  @spec create_environment_variable(key :: String.t(), opts :: Keyword.t()) :: Http.response()
  def create_environment_variable(key, opts \\ []) do
    body =
      %{key: key}
      |> add_optional_value(:type, opts[:type])
      |> add_optional_value(:isSecret, opts[:is_secret])
      |> add_optional_value(:values, opts[:values])

    Http.post("/v1/environment-variables", body)
  end

  @doc """
  Retrieves an environment variable by key.

  [API Documentation](https://docs.novu.co/api-reference/environment-variables/get-environment-variable)
  """
  @spec get_environment_variable(key :: String.t()) :: Http.response()
  def get_environment_variable(key), do: key |> variable_path() |> Http.get()

  @doc """
  Updates an existing environment variable.

  Providing `:values` merges them into the existing per-environment values by
  `_environmentId`.

  ## Options

    * `:key` - a new key for the variable
    * `:type` - the type of the variable
    * `:is_secret` - whether the variable is a secret
    * `:values` - list of per-environment values (see `create_environment_variable/2`)

  [API Documentation](https://docs.novu.co/api-reference/environment-variables/update-a-variable)
  """
  @spec update_environment_variable(key :: String.t(), opts :: Keyword.t()) :: Http.response()
  def update_environment_variable(key, opts \\ []) do
    body =
      %{}
      |> add_optional_value(:key, opts[:key])
      |> add_optional_value(:type, opts[:type])
      |> add_optional_value(:isSecret, opts[:is_secret])
      |> add_optional_value(:values, opts[:values])

    key |> variable_path() |> Http.patch(body)
  end

  @doc """
  Deletes an environment variable by key.

  [API Documentation](https://docs.novu.co/api-reference/environment-variables/delete-environment-variable)
  """
  @spec delete_environment_variable(key :: String.t()) :: Http.response()
  def delete_environment_variable(key), do: key |> variable_path() |> Http.delete()

  @doc """
  Retrieves the workflows that reference the environment variable.

  [API Documentation](https://docs.novu.co/api-reference/environment-variables/retrieve-a-variable-usage)
  """
  @spec get_environment_variable_usage(key :: String.t()) :: Http.response()
  def get_environment_variable_usage(key), do: Http.get(variable_path(key) <> "/usage")

  defp variable_path(key), do: "/v1/environment-variables/#{Http.path_segment(key)}"

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
