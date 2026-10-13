defmodule Novu.AgentsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Agents

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

  describe "list_agents/1" do
    test "creates a GET to /v1/agents", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/agents", fn conn -> novu_response(conn, 200, %{data: []}) end)
      assert {:ok, _} = Agents.list_agents()
    end

    test "supports query options", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/agents", fn conn ->
        assert %{
                 "after" => "a",
                 "before" => "b",
                 "limit" => "5",
                 "orderDirection" => "ASC",
                 "orderBy" => "name",
                 "includeCursor" => "true",
                 "identifier" => "bot"
               } = conn.query_params

        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Agents.list_agents(
                 after: "a",
                 before: "b",
                 limit: 5,
                 order_direction: "ASC",
                 order_by: "name",
                 include_cursor: true,
                 identifier: "bot"
               )
    end
  end

  describe "create_agent/1" do
    test "creates a POST passing attrs through", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/agents", fn conn ->
        assert %{"name" => "Bot", "identifier" => "bot", "runtime" => "managed"} = read_json_body(conn)
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} = Agents.create_agent(%{name: "Bot", identifier: "bot", runtime: "managed"})
    end
  end

  describe "get_agent/1" do
    test "creates a GET and escapes the identifier", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/agents/a%2Fb", fn conn ->
        assert conn.request_path == "/v1/agents/a%2Fb"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Agents.get_agent("a/b")
    end
  end

  describe "update_agent/2" do
    test "creates a PATCH passing attrs through", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v1/agents/bot", fn conn ->
        assert %{"name" => "New", "devBridgeActive" => true} = read_json_body(conn)
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Agents.update_agent("bot", %{name: "New", devBridgeActive: true})
    end
  end

  describe "delete_agent/2" do
    test "creates a DELETE", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/agents/bot", fn conn ->
        assert conn.query_string == ""
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Agents.delete_agent("bot")
    end

    test "supports delete_from_provider", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/agents/bot", fn conn ->
        assert %{"deleteFromProvider" => "true"} = conn.query_params
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Agents.delete_agent("bot", delete_from_provider: true)
    end
  end

  describe "update_agent_bridge/2" do
    test "creates a PUT to /bridge", %{bypass: bypass} do
      Bypass.expect(bypass, "PUT", "/v1/agents/bot/bridge", fn conn ->
        assert %{"bridgeUrl" => "https://x.test", "devBridgeUrl" => "https://d.test", "devBridgeActive" => false} =
                 read_json_body(conn)

        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} =
               Agents.update_agent_bridge("bot", %{
                 bridgeUrl: "https://x.test",
                 devBridgeUrl: "https://d.test",
                 devBridgeActive: false
               })
    end
  end

  describe "list_agent_integrations/2" do
    test "creates a GET to /integrations", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/agents/bot/integrations", fn conn -> novu_response(conn, 200, %{data: []}) end)
      assert {:ok, _} = Agents.list_agent_integrations("bot")
    end

    test "supports query options", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/agents/bot/integrations", fn conn ->
        assert %{
                 "after" => "a",
                 "before" => "b",
                 "limit" => "5",
                 "orderDirection" => "DESC",
                 "orderBy" => "createdAt",
                 "includeCursor" => "false",
                 "integrationIdentifier" => "slack-support"
               } = conn.query_params

        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Agents.list_agent_integrations("bot",
                 after: "a",
                 before: "b",
                 limit: 5,
                 order_direction: "DESC",
                 order_by: "createdAt",
                 include_cursor: false,
                 integration_identifier: "slack-support"
               )
    end
  end

  describe "create_agent_integration/2" do
    test "creates a POST to /integrations", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/agents/bot/integrations", fn conn ->
        assert %{"integrationIdentifier" => "slack-support", "providerId" => "novu-agent-email"} = read_json_body(conn)
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} =
               Agents.create_agent_integration("bot", %{
                 integrationIdentifier: "slack-support",
                 providerId: "novu-agent-email"
               })
    end
  end

  describe "update_agent_integration/3" do
    test "creates a PATCH to /integrations/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v1/agents/bot/integrations/link-1", fn conn ->
        assert %{"integrationIdentifier" => "slack-2"} = read_json_body(conn)
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Agents.update_agent_integration("bot", "link-1", %{integrationIdentifier: "slack-2"})
    end
  end

  describe "delete_agent_integration/2" do
    test "creates a DELETE to /integrations/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/agents/bot/integrations/link-1", fn conn -> Plug.Conn.resp(conn, 204, "") end)

      assert {:ok, _} = Agents.delete_agent_integration("bot", "link-1")
    end
  end
end
