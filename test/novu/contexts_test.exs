defmodule Novu.ContextsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Contexts

  @test_api_key "test-api-key"

  setup do
    bypass = Bypass.open()

    current_domain = Application.get_env(:novu, :domain)

    Application.put_env(:novu, :domain, "http://localhost:#{bypass.port}")
    Application.put_env(:novu, :api_key, @test_api_key)

    on_exit(fn ->
      Application.put_env(:novu, :domain, current_domain)
    end)

    {:ok, bypass: bypass}
  end

  describe "create_context/3" do
    test "creates a POST to /v2/contexts with type and id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v2/contexts", fn conn ->
        assert read_json_body(conn) == %{"type" => "tenant", "id" => "acme"}
        novu_response(conn, 201, %{type: "tenant", id: "acme"})
      end)

      assert {:ok, _} = Contexts.create_context("tenant", "acme")
    end

    test "sends data and bridgeUrl", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v2/contexts", fn conn ->
        body = read_json_body(conn)
        assert body["data"] == %{"plan" => "pro"}
        assert body["bridgeUrl"] == "https://example.com/bridge"
        novu_response(conn, 201, %{type: "tenant", id: "acme"})
      end)

      assert {:ok, _} =
               Contexts.create_context("tenant", "acme", data: %{plan: "pro"}, bridge_url: "https://example.com/bridge")
    end
  end

  describe "list_contexts/1" do
    test "creates a GET to /v2/contexts", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/contexts", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = Contexts.list_contexts()
    end

    test "sends all filters as query params", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/contexts", fn conn ->
        assert conn.query_params == %{
                 "after" => "a",
                 "before" => "b",
                 "limit" => "10",
                 "orderDirection" => "ASC",
                 "orderBy" => "createdAt",
                 "includeCursor" => "true",
                 "id" => "acme",
                 "search" => "ten"
               }

        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Contexts.list_contexts(
                 after: "a",
                 before: "b",
                 limit: 10,
                 order_direction: "ASC",
                 order_by: "createdAt",
                 include_cursor: true,
                 id: "acme",
                 search: "ten"
               )
    end
  end

  describe "get_context/2" do
    test "creates a GET to /v2/contexts/:type/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/contexts/tenant/acme", fn conn ->
        novu_response(conn, 200, %{type: "tenant", id: "acme"})
      end)

      assert {:ok, _} = Contexts.get_context("tenant", "acme")
    end

    test "escapes path segments", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/contexts/ten%2Fant/a%20b", fn conn ->
        assert conn.request_path == "/v2/contexts/ten%2Fant/a%20b"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Contexts.get_context("ten/ant", "a b")
    end
  end

  describe "update_context/3" do
    test "creates a PATCH with data and bridgeUrl", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v2/contexts/tenant/acme", fn conn ->
        body = read_json_body(conn)
        assert body["data"] == %{"plan" => "free"}
        assert body["bridgeUrl"] == "https://example.com/b"
        novu_response(conn, 200, %{type: "tenant", id: "acme"})
      end)

      assert {:ok, _} =
               Contexts.update_context("tenant", "acme", data: %{plan: "free"}, bridge_url: "https://example.com/b")
    end
  end

  describe "delete_context/2" do
    test "creates a DELETE to /v2/contexts/:type/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/v2/contexts/tenant/acme", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Contexts.delete_context("tenant", "acme")
    end
  end
end
