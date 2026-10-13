defmodule Novu.IntegrationsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Integrations

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
    test "integration id containing a slash is escaped", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/v1/integrations/a%2Fb", fn conn ->
        assert conn.request_path == "/v1/integrations/a%2Fb"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Integrations.delete_integration("a/b")
    end
  end

  describe "list_integrations/0" do
    test "creates a GET to /v1/integrations", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/integrations", fn conn ->
        novu_response(conn, 200, [])
      end)

      assert {:ok, _} = Integrations.list_integrations()
    end
  end

  describe "list_active_integrations/0" do
    test "creates a GET to /v1/integrations/active", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/integrations/active", fn conn ->
        novu_response(conn, 200, [])
      end)

      assert {:ok, _} = Integrations.list_active_integrations()
    end
  end

  describe "create_integration/3" do
    test "creates a POST to /v1/integrations with provider and channel", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations", fn conn ->
        body = read_json_body(conn)
        assert body == %{"providerId" => "sendgrid", "channel" => "email"}
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} = Integrations.create_integration("sendgrid", "email")
    end

    test "sends every optional field with its API key", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations", fn conn ->
        body = read_json_body(conn)
        assert body["name"] == "n"
        assert body["identifier"] == "i"
        assert body["_environmentId"] == "env"
        assert body["kind"] == "delivery"
        assert body["credentials"] == %{"apiKey" => "k"}
        assert body["active"] == true
        assert body["check"] == false
        assert body["conditions"] == [%{"isNegated" => false}]
        assert body["rules"] == %{"and" => []}
        assert body["configurations"] == %{"a" => 1}
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} =
               Integrations.create_integration("sendgrid", "email",
                 name: "n",
                 identifier: "i",
                 environment_id: "env",
                 kind: "delivery",
                 credentials: %{apiKey: "k"},
                 active: true,
                 check: false,
                 conditions: [%{isNegated: false}],
                 rules: %{and: []},
                 configurations: %{a: 1}
               )
    end
  end

  describe "update_integration/2" do
    test "creates a PUT to /v1/integrations/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "PUT", "/v1/integrations/int1", fn conn ->
        assert read_json_body(conn) == %{}
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Integrations.update_integration("int1")
    end

    test "sends every optional field with its API key", %{bypass: bypass} do
      Bypass.expect(bypass, "PUT", "/v1/integrations/int1", fn conn ->
        body = read_json_body(conn)
        assert body["name"] == "n"
        assert body["identifier"] == "i"
        assert body["_environmentId"] == "env"
        assert body["credentials"] == %{"apiKey" => "k"}
        assert body["active"] == true
        assert body["check"] == false
        assert body["conditions"] == []
        assert body["rules"] == %{"and" => []}
        assert body["configurations"] == %{"a" => 1}
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} =
               Integrations.update_integration("int1",
                 name: "n",
                 identifier: "i",
                 environment_id: "env",
                 credentials: %{apiKey: "k"},
                 active: true,
                 check: false,
                 conditions: [],
                 rules: %{and: []},
                 configurations: %{a: 1}
               )
    end
  end

  describe "delete_integration/1" do
    test "creates a DELETE to /v1/integrations/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/integrations/int1", fn conn ->
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Integrations.delete_integration("int1")
    end
  end

  describe "set_integration_as_primary/1" do
    test "creates a POST to /v1/integrations/:id/set-primary", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations/int1/set-primary", fn conn ->
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Integrations.set_integration_as_primary("int1")
    end
  end

  describe "auto_configure_integration/1" do
    test "creates a POST to /v1/integrations/:id/auto-configure", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations/int1/auto-configure", fn conn ->
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Integrations.auto_configure_integration("int1")
    end
  end

  describe "configure_integration_webhook/2" do
    test "creates a POST to /v1/integrations/:identifier/webhook/configure", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations/tg/webhook/configure", fn conn ->
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Integrations.configure_integration_webhook("tg", %{})
    end
  end

  describe "create_mobile_link/2" do
    test "creates a POST to /v1/integrations/:identifier/mobile-link", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations/tg/mobile-link", fn conn ->
        assert read_json_body(conn) == %{"subscriberId" => "sub1"}
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Integrations.create_mobile_link("tg", %{subscriberId: "sub1"})
    end
  end

  describe "generate_channel_connection_oauth_url/1" do
    test "creates a POST to /v1/integrations/channel-connections/oauth", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations/channel-connections/oauth", fn conn ->
        assert read_json_body(conn) == %{"integrationIdentifier" => "slack"}
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} = Integrations.generate_channel_connection_oauth_url(%{integrationIdentifier: "slack"})
    end
  end

  describe "generate_channel_endpoint_oauth_url/1" do
    test "creates a POST to /v1/integrations/channel-endpoints/oauth", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations/channel-endpoints/oauth", fn conn ->
        assert read_json_body(conn) == %{"integrationIdentifier" => "slack", "subscriberId" => "s"}
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} =
               Integrations.generate_channel_endpoint_oauth_url(%{integrationIdentifier: "slack", subscriberId: "s"})
    end
  end

  describe "create_channel_endpoint_link/1" do
    test "creates a POST to /v1/integrations/channel-endpoints/link", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/integrations/channel-endpoints/link", fn conn ->
        assert read_json_body(conn) == %{"integrationIdentifier" => "tg", "subscriberId" => "s"}
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Integrations.create_channel_endpoint_link(%{integrationIdentifier: "tg", subscriberId: "s"})
    end
  end
end
