defmodule Novu.HttpTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Http

  @test_api_key "test-api-key"
  @test_retry_log_level false

  setup do
    bypass = Bypass.open()

    current_domain = Application.get_env(:novu, :domain)

    Application.put_env(:novu, :domain, "http://localhost:#{bypass.port}")
    Application.put_env(:novu, :api_key, @test_api_key)
    Application.put_env(:novu, :retry_log_level, @test_retry_log_level)

    on_exit(fn ->
      Application.put_env(:novu, :domain, current_domain)
    end)

    {:ok, bypass: bypass}
  end

  describe "build_req/1" do
    test "default maximum retry should be zero", %{bypass: bypass} do
      wait_min = 100
      Application.put_env(:novu, :wait_min, wait_min)
      Application.delete_env(:novu, :max_retries)

      Bypass.expect_once(bypass, "GET", "/", fn conn ->
        novu_response(conn, 500, %{data: %{error: "Internal Server Error"}})
      end)

      Http.get("/")
    end

    test "creates a request with a minimum delay", %{bypass: bypass} do
      wait_min = 100
      Application.put_env(:novu, :wait_min, wait_min)
      Application.put_env(:novu, :max_retries, 1)

      Bypass.expect(bypass, "GET", "/", fn conn ->
        novu_response(conn, 500, %{data: %{error: "Internal Server Error"}})
      end)

      start_timer = Time.utc_now()
      Http.get("/")
      stop_timer = Time.utc_now()

      assert_in_delta wait_min, Time.diff(stop_timer, start_timer, :millisecond), 50
    end

    test "creates a request with a maximum delay", %{bypass: bypass} do
      wait_max = 100
      Application.put_env(:novu, :wait_min, 100)
      Application.put_env(:novu, :wait_max, wait_max)
      Application.put_env(:novu, :max_retries, 2)

      Bypass.expect(bypass, "GET", "/", fn conn ->
        novu_response(conn, 500, %{data: %{error: "Internal Server Error"}})
      end)

      start_timer = Time.utc_now()
      Http.get("/")
      stop_timer = Time.utc_now()
      assert_in_delta 200, Time.diff(stop_timer, start_timer, :millisecond), 50
    end

    test "retry based on Retry-After header", %{bypass: bypass} do
      Application.put_env(:novu, :max_retries, 1)

      Bypass.expect(bypass, "GET", "/", fn conn ->
        novu_response(conn, 429, %{data: %{error: "Internal Server Error"}}, headers: %{"Retry-After" => "2"})
      end)

      start_timer = Time.utc_now()
      Http.get("/")
      stop_timer = Time.utc_now()

      assert_in_delta 2000, Time.diff(stop_timer, start_timer, :millisecond), 50
    end
  end

  defp call(:delete, url, opts), do: Http.delete(url, opts)
  defp call(verb, url, opts), do: apply(Http, verb, [url, %{}, opts])

  describe "query params" do
    for verb <- [:post, :patch, :put, :delete] do
      test "#{verb} sends query params", %{bypass: bypass} do
        verb = unquote(verb)
        method = verb |> to_string() |> String.upcase()

        Bypass.expect_once(bypass, method, "/q", fn conn ->
          conn = Plug.Conn.fetch_query_params(conn)
          assert conn.query_params == %{"a" => "1", "b" => "true"}
          novu_response(conn, 200, %{})
        end)

        opts = [params: %{a: 1, b: true, c: nil}]

        assert {:ok, _} = call(verb, "/q", opts)
      end
    end

    test "list values are encoded as repeated keys and nil dropped", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/q", fn conn ->
        assert conn.query_string == "a=1&a=2&b=x+y"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Http.get("/q", a: [1, 2], b: "x y", c: nil)
    end

    test "get merges positional params with opts[:params]", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/q", fn conn ->
        assert Plug.Conn.fetch_query_params(conn).query_params == %{"a" => "1", "b" => "2"}
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Http.get("/q", %{a: 1}, params: [b: 2])
    end
  end

  describe "bodies and headers" do
    test "delete sends a JSON body", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/d", fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]
        assert read_json_body(conn) == %{"ids" => ["a", "b"]}
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Http.delete("/d", json: %{ids: ["a", "b"]})
    end

    test "custom idempotency key and headers", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/p", fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["my-key"]
        assert Plug.Conn.get_req_header(conn, "x-custom") == ["yes"]
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Http.post("/p", %{}, idempotency_key: "my-key", headers: [{"x-custom", "yes"}])
    end

    test "generates an idempotency key for non-GET requests", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/p", fn conn ->
        assert [key] = Plug.Conn.get_req_header(conn, "idempotency-key")
        assert key != ""
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Http.post("/p", %{})
    end

    test "no idempotency key on GET", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/g", fn conn ->
        assert Plug.Conn.get_req_header(conn, "idempotency-key") == []
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Http.get("/g")
    end

    test "user agent has no space", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/g", fn conn ->
        assert [<<"novu/elixir@", v::binary>>] = Plug.Conn.get_req_header(conn, "user-agent")
        refute String.starts_with?(v, " ")
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Http.get("/g")
    end

    test "multipart request", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/m", fn conn ->
        assert [ct] = Plug.Conn.get_req_header(conn, "content-type")
        assert String.starts_with?(ct, "multipart/form-data; boundary=")
        {:ok, body, _} = Plug.Conn.read_body(conn)
        assert body =~ ~s(name="file")
        assert body =~ "file-contents"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} =
               Http.post("/m", nil,
                 form_multipart: [file: {"file-contents", filename: "a.txt", content_type: "text/plain"}]
               )
    end
  end

  describe "path_segment/1" do
    test "escapes reserved characters" do
      assert Http.path_segment("a/b c?d") == "a%2Fb%20c%3Fd"
      assert Http.path_segment(123) == "123"
    end
  end
end
