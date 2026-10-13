defmodule Novu.DomainsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Domains

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

  describe "list_domains/1" do
    test "creates a GET to /v1/domains", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/domains", fn conn -> novu_response(conn, 200, %{data: []}) end)
      assert {:ok, _} = Domains.list_domains()
    end

    test "supports query options", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/domains", fn conn ->
        assert %{
                 "after" => "a",
                 "before" => "b",
                 "limit" => "5",
                 "orderDirection" => "ASC",
                 "orderBy" => "name",
                 "includeCursor" => "true",
                 "name" => "recent"
               } = conn.query_params

        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Domains.list_domains(
                 after: "a",
                 before: "b",
                 limit: 5,
                 order_direction: "ASC",
                 order_by: "name",
                 include_cursor: true,
                 name: "recent"
               )
    end
  end

  describe "create_domain/2" do
    test "creates a POST to /v1/domains with the name", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/domains", fn conn ->
        assert %{"name" => "recent.dev"} = body = read_json_body(conn)
        refute Map.has_key?(body, "data")
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} = Domains.create_domain("recent.dev")
    end

    test "supports data", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/domains", fn conn ->
        assert %{"data" => %{"k" => "v"}} = read_json_body(conn)
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} = Domains.create_domain("recent.dev", data: %{"k" => "v"})
    end
  end

  describe "get_domain/1" do
    test "creates a GET to /v1/domains/:domain", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/domains/recent.dev", fn conn -> novu_response(conn, 200, %{}) end)
      assert {:ok, _} = Domains.get_domain("recent.dev")
    end
  end

  describe "update_domain/2" do
    test "creates a PATCH with data", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v1/domains/recent.dev", fn conn ->
        assert %{"data" => %{"k" => "v"}} = read_json_body(conn)
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Domains.update_domain("recent.dev", data: %{"k" => "v"})
    end
  end

  describe "delete_domain/1" do
    test "creates a DELETE", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/domains/recent.dev", fn conn -> Plug.Conn.resp(conn, 204, "") end)
      assert {:ok, _} = Domains.delete_domain("recent.dev")
    end
  end

  describe "verify_domain/1" do
    test "creates a POST to /verify", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/domains/recent.dev/verify", fn conn -> novu_response(conn, 200, %{}) end)
      assert {:ok, _} = Domains.verify_domain("recent.dev")
    end
  end

  describe "diagnose_domain/1" do
    test "creates a POST to /diagnose", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/domains/recent.dev/diagnose", fn conn -> novu_response(conn, 200, %{}) end)
      assert {:ok, _} = Domains.diagnose_domain("recent.dev")
    end
  end

  describe "get_domain_auto_configure/1" do
    test "creates a GET to /auto-configure", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/domains/recent.dev/auto-configure", fn conn ->
        novu_response(conn, 200, %{available: false})
      end)

      assert {:ok, _} = Domains.get_domain_auto_configure("recent.dev")
    end
  end

  describe "start_domain_auto_configure/2" do
    test "creates a POST with redirectUri", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/domains/recent.dev/auto-configure/start", fn conn ->
        assert %{"redirectUri" => "https://x.test/back"} = read_json_body(conn)
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} = Domains.start_domain_auto_configure("recent.dev", redirect_uri: "https://x.test/back")
    end
  end

  describe "list_domain_routes/2" do
    test "creates a GET to /routes", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/domains/recent.dev/routes", fn conn -> novu_response(conn, 200, %{data: []}) end)

      assert {:ok, _} = Domains.list_domain_routes("recent.dev")
    end

    test "supports query options", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/domains/recent.dev/routes", fn conn ->
        assert %{
                 "after" => "a",
                 "before" => "b",
                 "limit" => "5",
                 "orderDirection" => "DESC",
                 "orderBy" => "address",
                 "includeCursor" => "true",
                 "agentId" => "agent-1"
               } = conn.query_params

        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Domains.list_domain_routes("recent.dev",
                 after: "a",
                 before: "b",
                 limit: 5,
                 order_direction: "DESC",
                 order_by: "address",
                 include_cursor: true,
                 agent_id: "agent-1"
               )
    end
  end

  describe "create_domain_route/3" do
    test "creates a POST with address and optional fields", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/domains/recent.dev/routes", fn conn ->
        assert %{
                 "address" => "support",
                 "type" => "agent",
                 "agentId" => "agent-1",
                 "data" => %{"k" => "v"}
               } = read_json_body(conn)

        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} =
               Domains.create_domain_route("recent.dev", "support",
                 type: "agent",
                 agent_id: "agent-1",
                 data: %{"k" => "v"}
               )
    end
  end

  describe "get_domain_route/2" do
    test "creates a GET and escapes the address", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/domains/recent.dev/routes/a%2Bb.c", fn conn ->
        assert conn.request_path == "/v1/domains/recent.dev/routes/a%2Bb.c"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Domains.get_domain_route("recent.dev", "a+b.c")
    end
  end

  describe "update_domain_route/3" do
    test "creates a PATCH with optional fields", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v1/domains/recent.dev/routes/support", fn conn ->
        assert %{"type" => "webhook", "agentId" => "agent-2", "data" => %{"k" => "v"}} = read_json_body(conn)
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} =
               Domains.update_domain_route("recent.dev", "support",
                 type: "webhook",
                 agent_id: "agent-2",
                 data: %{"k" => "v"}
               )
    end
  end

  describe "delete_domain_route/2" do
    test "creates a DELETE", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/domains/recent.dev/routes/support", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Domains.delete_domain_route("recent.dev", "support")
    end
  end

  describe "test_domain_route/3" do
    test "creates a POST to /test with body fields", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/domains/recent.dev/routes/a%2Bb/test", fn conn ->
        assert %{
                 "from" => %{"address" => "me@x.test", "name" => "Me"},
                 "subject" => "Hi",
                 "text" => "t",
                 "html" => "<p>t</p>",
                 "dryRun" => true
               } = read_json_body(conn)

        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} =
               Domains.test_domain_route("recent.dev", "a+b",
                 from: %{"address" => "me@x.test", "name" => "Me"},
                 subject: "Hi",
                 text: "t",
                 html: "<p>t</p>",
                 dry_run: true
               )
    end
  end
end
