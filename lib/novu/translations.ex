defmodule Novu.Translations do
  @moduledoc """
  Provide access to the Novu Translations API (`/v2/translations`).

  `resource_type` is `"workflow"` or `"layout"`. Functions that take `attrs`
  accept a plain map in the API's camelCase shape and pass it through unchanged.

  ## File uploads

  `upload_master_json/1` and `upload_translation_files/3` send
  `multipart/form-data`. A file can be given as either:

    * a path to a file on disk (the file name is taken from the path), or
    * a `{filename, binary}` tuple with the contents already in memory.

  The file name must be the locale followed by `.json`, e.g. `en_US.json`, as
  the API detects the locale from it. If a file cannot be read the function
  returns `{:error, {:file_error, path, reason}}` without making a request.
  """

  alias Novu.Http

  @type file() :: Path.t() | {filename :: String.t(), content :: binary()}

  @doc """
  Creates a translation for a resource and locale. If it already exists it is updated.

  `attrs` is passed through as the request body. Required keys: `resourceId`,
  `resourceType`, `locale` and `content` (the translation content as a map).

  [API Documentation](https://docs.novu.co/api-reference/translations/create-a-translation)
  """
  @spec create_translation(attrs :: map()) :: Http.response()
  def create_translation(attrs), do: Http.post("/v2/translations", attrs)

  @doc """
  Retrieves a translation by resource type, resource ID and locale.

  [API Documentation](https://docs.novu.co/api-reference/translations/retrieve-a-translation)
  """
  @spec get_translation(resource_type :: String.t(), resource_id :: String.t(), locale :: String.t()) ::
          Http.response()
  def get_translation(resource_type, resource_id, locale),
    do: resource_type |> translation_path(resource_id, locale) |> Http.get()

  @doc """
  Deletes a translation by resource type, resource ID and locale.

  [API Documentation](https://docs.novu.co/api-reference/translations/delete-a-translation)
  """
  @spec delete_translation(resource_type :: String.t(), resource_id :: String.t(), locale :: String.t()) ::
          Http.response()
  def delete_translation(resource_type, resource_id, locale),
    do: resource_type |> translation_path(resource_id, locale) |> Http.delete()

  @doc """
  Retrieves a translation group by resource type and resource ID.

  [API Documentation](https://docs.novu.co/api-reference/translations/retrieve-a-translation-group)
  """
  @spec get_translation_group(resource_type :: String.t(), resource_id :: String.t()) :: Http.response()
  def get_translation_group(resource_type, resource_id) do
    Http.get("/v2/translations/group/#{Http.path_segment(resource_type)}/#{Http.path_segment(resource_id)}")
  end

  @doc """
  Deletes a translation group and all of its translations.

  [API Documentation](https://docs.novu.co/api-reference/translations/delete-a-translation-group)
  """
  @spec delete_translation_group(resource_type :: String.t(), resource_id :: String.t()) :: Http.response()
  def delete_translation_group(resource_type, resource_id) do
    Http.delete("/v2/translations/#{Http.path_segment(resource_type)}/#{Http.path_segment(resource_id)}")
  end

  @doc """
  Retrieves all translations for a locale in master JSON format.

  ## Options

    * `:locale` - locale to export, defaults to the organization default locale

  [API Documentation](https://docs.novu.co/api-reference/translations/retrieve-master-translations-json)
  """
  @spec get_master_json(opts :: Keyword.t()) :: Http.response()
  def get_master_json(opts \\ []) do
    params = add_optional_value(%{}, :locale, opts[:locale])

    Http.get("/v2/translations/master-json", params)
  end

  @doc """
  Imports translations for multiple workflows from master JSON format.

  `attrs` is passed through as the request body. Required keys: `locale` and
  `masterJson` (a map organized by workflow identifier).

  [API Documentation](https://docs.novu.co/api-reference/translations/import-master-translations-json)
  """
  @spec import_master_json(attrs :: map()) :: Http.response()
  def import_master_json(attrs), do: Http.post("/v2/translations/master-json", attrs)

  @doc """
  Uploads a master JSON file containing translations for multiple workflows.

  The locale is detected from the file name (e.g. `en_US.json`). See the module
  documentation for the accepted `file` forms. The file is sent in the `file`
  form field.

  [API Documentation](https://docs.novu.co/api-reference/translations/upload-master-translations-json-file)
  """
  @spec upload_master_json(file :: file()) :: Http.response()
  def upload_master_json(file) do
    with {:ok, part} <- file_part("file", file) do
      Http.post("/v2/translations/master-json/upload", nil, form_multipart: [part])
    end
  end

  @doc """
  Uploads one or more JSON translation files for a resource.

  `files` is a list of files (see the module documentation for the accepted
  forms). Each file name must be the locale, e.g. `en_US.json`. Files are sent
  in the `files` form field, together with `resourceId` and `resourceType`.

  [API Documentation](https://docs.novu.co/api-reference/translations/upload-translation-files)
  """
  @spec upload_translation_files(resource_type :: String.t(), resource_id :: String.t(), files :: [file()]) ::
          Http.response()
  def upload_translation_files(resource_type, resource_id, files) do
    with {:ok, parts} <- file_parts("files", files) do
      form = [{"resourceId", resource_id}, {"resourceType", resource_type}] ++ parts
      Http.post("/v2/translations/upload", nil, form_multipart: form)
    end
  end

  defp file_parts(field, files), do: file_parts(field, files, [])

  defp file_parts(_field, [], acc), do: {:ok, Enum.reverse(acc)}

  defp file_parts(field, [file | rest], acc) do
    case file_part(field, file) do
      {:ok, part} -> file_parts(field, rest, [part | acc])
      {:error, _} = error -> error
    end
  end

  defp file_part(field, {filename, content}) when is_binary(filename) and is_binary(content) do
    {:ok, {field, {content, filename: filename, content_type: "application/json"}}}
  end

  defp file_part(field, path) when is_binary(path) do
    case File.read(path) do
      {:ok, content} -> file_part(field, {Path.basename(path), content})
      {:error, reason} -> {:error, {:file_error, path, reason}}
    end
  end

  defp translation_path(resource_type, resource_id, locale) do
    "/v2/translations/#{Http.path_segment(resource_type)}/#{Http.path_segment(resource_id)}/#{Http.path_segment(locale)}"
  end

  defp add_optional_value(map, _key, nil), do: map
  defp add_optional_value(map, key, value), do: Map.put(map, key, value)
end
