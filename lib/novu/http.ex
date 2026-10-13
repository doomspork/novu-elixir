defmodule Novu.Http do
  @moduledoc """
  A basic HTTP client for Novu using `Req`. Any request made with these modules
  will include base headers, authentication, response parsing, and error
  handling.
  """

  require Logger

  @user_agent "novu/elixir@" <> Mix.Project.config()[:version]

  @type response() :: {:ok, map()} | {:error, list() | :timeout | any()}

  @max_retries 0

  @typedoc """
  Options accepted by every request function:

    * `:params` - query params as a map or keyword list. List values are encoded
      as repeated keys (`a=1&a=2`) and `nil` values are dropped.
    * `:json` - JSON body, used by `delete/2` only.
    * `:idempotency_key` - overrides the generated `idempotency-key` header
      (not sent on `GET` requests).
    * `:headers` - extra request headers.
    * `:form_multipart` - sends a `multipart/form-data` body (see `Req`). Use
      with a `nil` body.
  """
  @type opts() :: [
          params: map() | keyword(),
          json: term(),
          idempotency_key: String.t(),
          headers: [{String.t(), String.t()}] | map(),
          form_multipart: [{atom() | String.t(), term()}]
        ]

  @doc """
  Makes a `DELETE` request to Novu.
  """
  @spec delete(url :: Req.url(), opts :: opts()) :: response()
  def delete(url, opts \\ []) do
    extra = if Keyword.has_key?(opts, :json), do: [json: opts[:json]], else: []
    request(:delete, url, opts, extra)
  end

  @doc """
  Makes a `GET` request to Novu.

  `params` are merged with `opts[:params]`.
  """
  @spec get(url :: Req.url(), params :: map() | keyword(), opts :: opts()) :: response()
  def get(url, params \\ %{}, opts \\ []) do
    opts = Keyword.update(opts, :params, params, &merge_params(params, &1))
    request(:get, url, opts, [])
  end

  @doc """
  Makes a `PATCH` request to Novu.
  """
  @spec patch(url :: Req.url(), body :: map() | nil, opts :: opts()) :: response()
  def patch(url, body, opts \\ []), do: request(:patch, url, opts, body_opts(body, opts))

  @doc """
  Makes a `POST` request to Novu.
  """
  @spec post(url :: Req.url(), body :: map() | nil, opts :: opts()) :: response()
  def post(url, body, opts \\ []), do: request(:post, url, opts, body_opts(body, opts))

  @doc """
  Makes a `PUT` request to Novu.
  """
  @spec put(url :: Req.url(), body :: map() | nil, opts :: opts()) :: response()
  def put(url, body, opts \\ []), do: request(:put, url, opts, body_opts(body, opts))

  @doc """
  Escapes a single URL path segment, including `/`, `?` and `#`.

  ## Examples

      iex> Novu.Http.path_segment("a/b c?d")
      "a%2Fb%20c%3Fd"
  """
  @spec path_segment(value :: term()) :: String.t()
  def path_segment(value), do: value |> to_string() |> URI.encode(&URI.char_unreserved?/1)

  defp merge_params(a, b), do: Enum.to_list(a) ++ Enum.to_list(b)

  defp body_opts(body, opts) do
    case Keyword.fetch(opts, :form_multipart) do
      {:ok, parts} -> [form_multipart: parts]
      :error -> [json: body]
    end
  end

  defp request(method, url, opts, req_opts) do
    url
    |> append_query(opts[:params])
    |> build_req(method, opts)
    |> Req.request!([method: method] ++ req_opts)
    |> handle_response()
  rescue
    e -> handle_response(e)
  end

  defp append_query(url, params) do
    url = to_string(url)

    case encode_query(params) do
      "" -> url
      query -> url <> if(String.contains?(url, "?"), do: "&", else: "?") <> query
    end
  end

  defp encode_query(nil), do: ""

  defp encode_query(params) do
    params
    |> Enum.flat_map(fn
      {_key, nil} -> []
      {key, values} when is_list(values) -> for v <- values, v != nil, do: {key, v}
      {key, value} -> [{key, value}]
    end)
    |> Enum.map_join("&", &encode_pair/1)
  end

  defp encode_pair({key, value}) do
    key = key |> to_string() |> URI.encode_www_form()
    value = value |> to_string() |> URI.encode_www_form()
    key <> "=" <> value
  end

  defp api_key, do: Application.fetch_env!(:novu, :api_key)

  defp base_domain, do: Application.fetch_env!(:novu, :domain)

  defp wait_min, do: Application.get_env(:novu, :wait_min, 1000)
  defp wait_max, do: Application.get_env(:novu, :wait_max, 10_000)
  defp max_retries, do: Application.get_env(:novu, :max_retries, @max_retries)
  defp retry_log_level, do: Application.get_env(:novu, :retry_log_level, :warning)

  defp retry_delay_function(n) do
    min(Integer.pow(2, n) * wait_min(), wait_max())
  end

  defp build_req(url, method, opts),
    do:
      Req.new(
        base_url: base_domain(),
        headers: request_headers(method, opts),
        url: url,
        user_agent: @user_agent,
        retry: :transient,
        retry_delay: &retry_delay_function/1,
        max_retries: max_retries(),
        retry_log_level: retry_log_level()
      )

  defp handle_response(%{body: body, status: status_code}) when status_code in 200..299, do: {:ok, body}
  defp handle_response(%{body: %{"errors" => errors}}), do: {:error, errors}
  defp handle_response(%Mint.TransportError{reason: :timeout}), do: {:error, :timeout}
  defp handle_response(response), do: {:error, response}

  defp request_headers(method, opts) do
    base = [{"accept", "application/json"}, {"authorization", "ApiKey #{api_key()}"}]

    idempotency =
      if method == :get, do: [], else: [{"idempotency-key", opts[:idempotency_key] || UUID.uuid4()}]

    base ++ idempotency ++ Enum.to_list(opts[:headers] || [])
  end
end
