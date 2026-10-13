defmodule Novu.NotificationGroups do
  @moduledoc """
  Provide access to the Novu Notification Groups API

  **Deprecated**: the `/v1/notification-groups` endpoints were removed from the Novu
  API. Use workflow `tags` (see `Novu.Workflows`) instead. Every function in this
  module is deprecated.
  """

  alias Novu.Http

  @doc """
  Creates a notification group

  **Deprecated**: the endpoint was removed from the Novu API; use workflow `tags` (`Novu.Workflows`).
  """
  @deprecated "The notification groups endpoints were removed from the Novu API; use workflow tags (Novu.Workflows)"
  @spec create_notification_group(name :: String.t()) :: Http.response()
  def create_notification_group(name) do
    Http.post("/v1/notification-groups", %{name: name})
  end

  @doc """
  Retrieves a list of notifications groups

  **Deprecated**: the endpoint was removed from the Novu API; use workflow `tags` (`Novu.Workflows`).
  """
  @deprecated "The notification groups endpoints were removed from the Novu API; use workflow tags (Novu.Workflows)"
  @spec get_notification_groups :: Http.response()
  def get_notification_groups do
    Http.get("/v1/notification-groups")
  end
end
