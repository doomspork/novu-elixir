defmodule Novu.NotificationsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Notifications

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

  describe "list_notifications/1" do
    test "creates a GET to /v1/notifications", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/notifications", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{page: 0, hasMore: false, pageSize: 10, data: []})
      end)

      assert {:ok, _body} = Notifications.list_notifications()
    end

    test "sends scalar filters as camelCase query params", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/notifications", fn conn ->
        assert conn.query_params["page"] == "1"
        assert conn.query_params["limit"] == "20"
        assert conn.query_params["transactionId"] == "tx-1"
        assert conn.query_params["topicKey"] == "topic-1"
        assert conn.query_params["subscriptionId"] == "subscr-1"
        assert conn.query_params["after"] == "2026-01-01T00:00:00Z"
        assert conn.query_params["before"] == "2026-02-01T00:00:00Z"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Notifications.list_notifications(
                 page: 1,
                 limit: 20,
                 transaction_id: "tx-1",
                 topic_key: "topic-1",
                 subscription_id: "subscr-1",
                 after: ~U[2026-01-01 00:00:00Z],
                 before: "2026-02-01T00:00:00Z"
               )
    end

    test "sends list filters as repeated keys", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/notifications", fn conn ->
        assert conn.query_string =~ "channels=email&channels=sms"
        assert conn.query_string =~ "templates=t1&templates=t2"
        assert conn.query_string =~ "emails=a%40b.com&emails=c%40d.com"
        assert conn.query_string =~ "subscriberIds=s1&subscriberIds=s2"
        assert conn.query_string =~ "severity=high&severity=low"
        assert conn.query_string =~ "contextKeys=tenant%3A1&contextKeys=org%3A2"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Notifications.list_notifications(
                 channels: ["email", "sms"],
                 templates: ["t1", "t2"],
                 emails: ["a@b.com", "c@d.com"],
                 subscriber_ids: ["s1", "s2"],
                 severity: ["high", "low"],
                 context_keys: ["tenant:1", "org:2"]
               )
    end
  end

  describe "get_notification/1" do
    test "creates a GET to /v1/notifications/{notificationId}", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/notifications/n-1", fn conn ->
        novu_response(conn, 200, %{data: %{_id: "n-1", jobs: []}})
      end)

      assert {:ok, _body} = Notifications.get_notification("n-1")
    end

    test "escapes the notification id", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/notifications/a%2Fb", fn conn ->
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _body} = Notifications.get_notification("a/b")
    end
  end
end
