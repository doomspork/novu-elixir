defmodule Novu.Subscribers.PreferencesTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Subscribers.Preferences

  @test_api_key "test-api-key"
  @path "/v2/subscribers/example-id/preferences"

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

  describe "get/2" do
    test "creates a GET to /v2/subscribers/{subscriberId}/preferences", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn ->
        novu_response(conn, 200, %{data: %{global: %{}, workflows: []}})
      end)

      assert {:ok, _body} = Preferences.get("example-id")
    end

    test "escapes the subscriber id", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/subscribers/a%2Fb/preferences", fn conn ->
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Preferences.get("a/b")
    end

    test "supports optional criticality", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn ->
        assert %{"criticality" => "nonCritical"} = conn.query_params
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Preferences.get("example-id", criticality: "nonCritical")
    end

    test "supports optional context_keys as repeated params", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @path, fn conn ->
        assert conn.query_string == "contextKeys=tenant%3Aacme&contextKeys=org%3A1"
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Preferences.get("example-id", context_keys: ["tenant:acme", "org:1"])
    end
  end

  describe "update/2" do
    test "creates a PATCH to /v2/subscribers/{subscriberId}/preferences", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @path, fn conn ->
        assert %{} == read_json_body(conn)
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Preferences.update("example-id")
    end

    test "supports optional channels", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @path, fn conn ->
        assert %{"channels" => %{"email" => true, "in_app" => false}} = read_json_body(conn)
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Preferences.update("example-id", channels: %{email: true, in_app: false})
    end

    test "supports optional workflow_id", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @path, fn conn ->
        assert %{"workflowId" => "welcome"} = read_json_body(conn)
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Preferences.update("example-id", workflow_id: "welcome")
    end

    test "supports optional schedule", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @path, fn conn ->
        assert %{"schedule" => %{"isEnabled" => true}} = read_json_body(conn)
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Preferences.update("example-id", schedule: %{isEnabled: true})
    end

    test "supports optional context", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @path, fn conn ->
        assert %{"context" => %{"tenant" => "acme"}} = read_json_body(conn)
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Preferences.update("example-id", context: %{tenant: "acme"})
    end
  end

  describe "bulk_update/3" do
    test "creates a PATCH to /v2/subscribers/{subscriberId}/preferences/bulk", %{bypass: bypass} do
      preferences = [%{workflowId: "welcome", channels: %{email: false}}]

      Bypass.expect(bypass, "PATCH", @path <> "/bulk", fn conn ->
        body = read_json_body(conn)
        assert %{"preferences" => [%{"workflowId" => "welcome", "channels" => %{"email" => false}}]} = body
        refute Map.has_key?(body, "context")
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _body} = Preferences.bulk_update("example-id", preferences)
    end

    test "supports optional context", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @path <> "/bulk", fn conn ->
        assert %{"context" => %{"tenant" => "acme"}} = read_json_body(conn)
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _body} = Preferences.bulk_update("example-id", [], context: %{tenant: "acme"})
    end
  end
end
