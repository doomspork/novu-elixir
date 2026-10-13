defmodule Novu.ChannelConnectionsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.ChannelConnections

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

  describe "path escaping" do
    test "identifier containing a slash is escaped", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/channel-connections/a%2Fb", fn conn ->
        assert conn.request_path == "/v1/channel-connections/a%2Fb"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = ChannelConnections.get_channel_connection("a/b")
    end
  end

  describe "list_channel_connections/1" do
    test "creates a GET to /v1/channel-connections", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/channel-connections", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = ChannelConnections.list_channel_connections()
    end

    test "sends every filter with its camelCase query key", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/channel-connections", fn conn ->
        assert conn.query_params["after"] == "c1"
        assert conn.query_params["before"] == "c2"
        assert conn.query_params["limit"] == "10"
        assert conn.query_params["orderDirection"] == "ASC"
        assert conn.query_params["orderBy"] == "createdAt"
        assert conn.query_params["includeCursor"] == "true"
        assert conn.query_params["subscriberId"] == "sub1"
        assert conn.query_params["channel"] == "chat"
        assert conn.query_params["providerId"] == "slack"
        assert conn.query_params["integrationIdentifier"] == "int1"
        assert conn.query_params["connectionMode"] == "shared"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               ChannelConnections.list_channel_connections(
                 after: "c1",
                 before: "c2",
                 limit: 10,
                 order_direction: "ASC",
                 order_by: "createdAt",
                 include_cursor: true,
                 subscriber_id: "sub1",
                 channel: "chat",
                 provider_id: "slack",
                 integration_identifier: "int1",
                 connection_mode: "shared"
               )
    end

    test "repeats context_keys in the query string", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/channel-connections", fn conn ->
        assert conn.query_string =~ "contextKeys=tenant%3A1&contextKeys=org%3A2"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = ChannelConnections.list_channel_connections(context_keys: ["tenant:1", "org:2"])
    end
  end

  describe "create_channel_connection/1" do
    test "creates a POST to /v1/channel-connections with the attrs", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/channel-connections", fn conn ->
        assert read_json_body(conn) == %{"integrationIdentifier" => "int1", "subscriberId" => "sub1"}
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} =
               ChannelConnections.create_channel_connection(%{integrationIdentifier: "int1", subscriberId: "sub1"})
    end
  end

  describe "get_channel_connection/1" do
    test "creates a GET to /v1/channel-connections/:identifier", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/channel-connections/id1", fn conn ->
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = ChannelConnections.get_channel_connection("id1")
    end
  end

  describe "update_channel_connection/2" do
    test "creates a PATCH to /v1/channel-connections/:identifier with the attrs", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v1/channel-connections/id1", fn conn ->
        assert read_json_body(conn) == %{"name" => "x"}
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = ChannelConnections.update_channel_connection("id1", %{name: "x"})
    end
  end

  describe "delete_channel_connection/1" do
    test "creates a DELETE to /v1/channel-connections/:identifier", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/channel-connections/id1", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = ChannelConnections.delete_channel_connection("id1")
    end
  end
end
