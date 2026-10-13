defmodule Novu.ExecutionDetails do
  @moduledoc """
  Provide access to the Novu Execution Details API
  """

  alias Novu.Http

  @doc """
  Retrieves execution details

  **Deprecated**: the endpoint was removed from the Novu API; use `Novu.Notifications.get_notification/1`.
  """
  @deprecated "The execution details endpoint was removed from the Novu API; use Novu.Notifications.get_notification/1"
  @spec get_execution_details :: Http.response()
  def get_execution_details do
    Http.get("/v1/execution-details")
  end
end
