defmodule Novu.EventsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Events

  @test_api_key "test-api-key"
  @recipient "test-user"

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

  describe "broadcast_to_all/3" do
    test "creates a POST to /v1/events/trigger/broadcast", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"})
    end

    test "supports optional transactionId", %{bypass: bypass} do
      transaction_id = "example-id"

      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        assert %{"transactionId" => ^transaction_id} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true, transactionId: transaction_id})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"}, transaction_id: transaction_id)
    end

    test "supports optional overrides", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        assert %{"overrides" => %{"two" => "dos"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"}, overrides: %{two: "dos"})
    end

    test "supports optional actor string", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        assert %{"actor" => "actor-1"} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"}, actor: "actor-1")
    end

    test "supports optional actor map", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        assert %{"actor" => %{"subscriberId" => "a1"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"}, actor: %{subscriberId: "a1"})
    end

    test "supports optional tenant string", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        assert %{"tenant" => "tenant-1"} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"}, tenant: "tenant-1")
    end

    test "supports optional tenant map", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        assert %{"tenant" => %{"identifier" => "t1"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"}, tenant: %{identifier: "t1"})
    end

    test "supports optional context", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        assert %{"context" => %{"k" => "v"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"}, context: %{k: "v"})
    end

    test "supports optional agentId", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/broadcast", fn conn ->
        assert %{"agentId" => "agent-1"} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.broadcast_to_all("test-event", %{one: "uno"}, agent_id: "agent-1")
    end
  end

  describe "bulk_trigger/1" do
    test "creates a POST to /v1/events/trigger/bulk with events body", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/bulk", fn conn ->
        assert %{"events" => [%{"name" => "a", "to" => "s1"}, %{"name" => "b", "to" => "s2"}]} = read_json_body(conn)
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _body} = Events.bulk_trigger([%{name: "a", to: "s1"}, %{name: "b", to: "s2"}])
    end

    test "accepts exactly 100 events", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger/bulk", fn conn ->
        assert %{"events" => events} = read_json_body(conn)
        assert length(events) == 100
        novu_response(conn, 201, %{})
      end)

      events = for i <- 1..100, do: %{name: "a", to: "s#{i}"}
      assert {:ok, _body} = Events.bulk_trigger(events)
    end

    test "raises ArgumentError for more than 100 events" do
      events = for i <- 1..101, do: %{name: "a", to: "s#{i}"}
      assert_raise ArgumentError, ~r/at most 100/, fn -> Events.bulk_trigger(events) end
    end
  end

  describe "cancel_event/1" do
    test "creates a DELETE to /v1/events/cancel/{transactionId}", %{bypass: bypass} do
      transaction_id = "example-id"

      Bypass.expect(bypass, "DELETE", "/v1/events/trigger/#{transaction_id}", fn conn ->
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _body} = Events.cancel_event(transaction_id)
    end

    test "escapes the transaction id", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/events/trigger/a%2Fb%3Fc", fn conn ->
        assert conn.request_path == "/v1/events/trigger/a%2Fb%3Fc"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _body} = Events.cancel_event("a/b?c")
    end
  end

  describe "trigger_event/4" do
    test "creates a POST to /v1/events/trigger", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, @recipient)
    end

    test "supports optional transactionId", %{bypass: bypass} do
      transaction_id = "example-id"

      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"transactionId" => ^transaction_id} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true, transactionId: transaction_id})
      end)

      assert {:ok, _body} =
               Events.trigger_event("test-event", %{one: "uno"}, @recipient, transaction_id: transaction_id)
    end

    test "supports optional overrides", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"overrides" => %{"two" => "dos"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, @recipient, overrides: %{two: "dos"})
    end

    test "supports optional actor string", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"actor" => "actor-1"} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, @recipient, actor: "actor-1")
    end

    test "supports optional actor map", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"actor" => %{"subscriberId" => "a1"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, @recipient, actor: %{subscriberId: "a1"})
    end

    test "supports optional tenant string", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"tenant" => "tenant-1"} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, @recipient, tenant: "tenant-1")
    end

    test "supports optional tenant map", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"tenant" => %{"identifier" => "t1"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, @recipient, tenant: %{identifier: "t1"})
    end

    test "supports optional context", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"context" => %{"k" => "v"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, @recipient, context: %{k: "v"})
    end

    test "supports optional agentId", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"agentId" => "agent-1"} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, @recipient, agent_id: "agent-1")
    end

    test "supports optional bridgeUrl", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"bridgeUrl" => "https://bridge.example"} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      assert {:ok, _body} =
               Events.trigger_event("test-event", %{one: "uno"}, @recipient, bridge_url: "https://bridge.example")
    end

    test "supports a subscriber object as recipient", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"to" => %{"subscriberId" => "s1", "email" => "a@example.com"}} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      to = %{subscriberId: "s1", email: "a@example.com"}
      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, to)
    end

    test "supports a list of mixed recipients", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/events/trigger", fn conn ->
        assert %{"to" => ["s1", %{"type" => "Topic", "topicKey" => "news"}]} = read_json_body(conn)
        novu_response(conn, 201, %{status: "pending", acknowledged: true})
      end)

      to = ["s1", %{type: "Topic", topicKey: "news"}]
      assert {:ok, _body} = Events.trigger_event("test-event", %{one: "uno"}, to)
    end
  end
end
