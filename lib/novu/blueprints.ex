defmodule Novu.Blueprints do
  @moduledoc """
  Provide access to the Novu Blueprints API

  **Deprecated**: the `/v1/blueprints` endpoints were removed from the Novu API and
  there is no replacement. Every function in this module is deprecated.
  """

  alias Novu.Http

  @doc """
  Retrieve a blueprint by its ID.

  **Deprecated**: the endpoint was removed from the Novu API; there is no replacement.
  """
  @deprecated "The blueprints endpoints were removed from the Novu API; there is no replacement"
  @spec get_blueprints(blueprint_id :: String.t()) :: Http.response()
  def get_blueprints(blueprint_id) do
    Http.get("/v1/blueprints/#{Http.path_segment(blueprint_id)}")
  end

  @doc """
  Returns blueprints grouped by category.

  **Deprecated**: the endpoint was removed from the Novu API; there is no replacement.
  """
  @deprecated "The blueprints endpoints were removed from the Novu API; there is no replacement"
  @spec get_group_by_category :: Http.response()
  def get_group_by_category do
    Http.get("/v1/blueprints/group-by-category")
  end
end
