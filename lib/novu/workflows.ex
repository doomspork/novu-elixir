defmodule Novu.Workflows do
  @moduledoc """
  Provide access to the Novu Workflows API (`/v2/workflows`).

  Workflow bodies are large and polymorphic (`steps` is a union of many step
  types), so they are not modelled. Functions that take `attrs` accept a plain
  map in the API's camelCase shape and pass it through unchanged.

  ## Example

      Novu.Workflows.create_workflow(%{
        name: "Welcome",
        workflowId: "welcome",
        steps: [
          %{
            name: "In-App",
            type: "in_app",
            controlValues: %{body: "Hello {{subscriber.firstName}}"}
          }
        ]
      })
  """

  alias Novu.Http

  @doc """
  Retrieves a list of workflows with optional filtering and pagination.

  ## Options

    * `:limit` - number of items to return per page
    * `:offset` - number of items to skip
    * `:order_direction` - `"ASC"` or `"DESC"`
    * `:order_by` - field to sort by
    * `:query` - search query
    * `:tags` - list of tags to filter by
    * `:status` - list of statuses to filter by

  [API Documentation](https://docs.novu.co/api-reference/workflows/list-all-workflows)
  """
  @spec list_workflows(opts :: Keyword.t()) :: Http.response()
  def list_workflows(opts \\ []) do
    params =
      %{}
      |> add_optional_value(:limit, opts[:limit])
      |> add_optional_value(:offset, opts[:offset])
      |> add_optional_value(:orderDirection, opts[:order_direction])
      |> add_optional_value(:orderBy, opts[:order_by])
      |> add_optional_value(:query, opts[:query])
      |> add_optional_value(:tags, opts[:tags])
      |> add_optional_value(:status, opts[:status])

    Http.get("/v2/workflows", params)
  end

  @doc """
  Creates a new workflow.

  `attrs` is passed through as the request body. Required keys: `name`,
  `workflowId` and `steps`.

  [API Documentation](https://docs.novu.co/api-reference/workflows/create-a-workflow)
  """
  @spec create_workflow(attrs :: map()) :: Http.response()
  def create_workflow(attrs), do: Http.post("/v2/workflows", attrs)

  @doc """
  Retrieves a workflow by its identifier.

  ## Options

    * `:environment_id` - environment to read the workflow from

  [API Documentation](https://docs.novu.co/api-reference/workflows/retrieve-a-workflow)
  """
  @spec get_workflow(workflow_id :: String.t(), opts :: Keyword.t()) :: Http.response()
  def get_workflow(workflow_id, opts \\ []) do
    params = add_optional_value(%{}, :environmentId, opts[:environment_id])
    workflow_id |> workflow_path() |> Http.get(params)
  end

  @doc """
  Replaces a workflow (full update).

  `attrs` is passed through as the request body. Required keys: `name`,
  `steps` and `preferences`.

  [API Documentation](https://docs.novu.co/api-reference/workflows/update-a-workflow)
  """
  @spec update_workflow(workflow_id :: String.t(), attrs :: map()) :: Http.response()
  def update_workflow(workflow_id, attrs), do: workflow_id |> workflow_path() |> Http.put(attrs)

  @doc """
  Partially updates a workflow.

  `attrs` is passed through as the request body. Supported keys include
  `active`, `name`, `description`, `tags`, `payloadSchema`, `validatePayload`
  and `isTranslationEnabled`.

  [API Documentation](https://docs.novu.co/api-reference/workflows/update-a-workflow)
  """
  @spec patch_workflow(workflow_id :: String.t(), attrs :: map()) :: Http.response()
  def patch_workflow(workflow_id, attrs), do: workflow_id |> workflow_path() |> Http.patch(attrs)

  @doc """
  Deletes a workflow.

  [API Documentation](https://docs.novu.co/api-reference/workflows/delete-a-workflow)
  """
  @spec delete_workflow(workflow_id :: String.t()) :: Http.response()
  def delete_workflow(workflow_id), do: workflow_id |> workflow_path() |> Http.delete()

  @doc """
  Synchronizes a workflow to the target environment.

  [API Documentation](https://docs.novu.co/api-reference/workflows/sync-a-workflow)
  """
  @spec sync_workflow(workflow_id :: String.t(), target_environment_id :: String.t()) :: Http.response()
  def sync_workflow(workflow_id, target_environment_id) do
    Http.put(workflow_path(workflow_id) <> "/sync", %{targetEnvironmentId: target_environment_id})
  end

  @doc """
  Retrieves a specific step of a workflow.

  [API Documentation](https://docs.novu.co/api-reference/workflows/retrieve-workflow-step)
  """
  @spec get_workflow_step(workflow_id :: String.t(), step_id :: String.t()) :: Http.response()
  def get_workflow_step(workflow_id, step_id) do
    Http.get(workflow_path(workflow_id) <> "/steps/#{Http.path_segment(step_id)}")
  end

  @doc """
  Generates a preview for a workflow step.

  `attrs` is passed through as the request body. Optional keys:
  `controlValues` and `previewPayload`.

  [API Documentation](https://docs.novu.co/api-reference/workflows/generate-a-step-preview)
  """
  @spec preview_workflow_step(workflow_id :: String.t(), step_id :: String.t(), attrs :: map()) :: Http.response()
  def preview_workflow_step(workflow_id, step_id, attrs) do
    Http.post(workflow_path(workflow_id) <> "/step/#{Http.path_segment(step_id)}/preview", attrs)
  end

  @doc """
  Duplicates a workflow.

  `attrs` is passed through as the request body. Keys: `name`, `workflowId`,
  `tags`, `description` and `isTranslationEnabled`.

  Note: this endpoint is present in the live API (`https://api.novu.co/api-json`)
  but is not yet in the published docs spec.

  [API Documentation](https://docs.novu.co/api-reference/workflows)
  """
  @spec duplicate_workflow(workflow_id :: String.t(), attrs :: map()) :: Http.response()
  def duplicate_workflow(workflow_id, attrs) do
    Http.post(workflow_path(workflow_id) <> "/duplicate", attrs)
  end

  defp workflow_path(workflow_id), do: "/v2/workflows/#{Http.path_segment(workflow_id)}"

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
