defmodule Novu.SubscribersTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Subscribers

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
    test "subscriber id containing a slash is escaped", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/subscribers/org%2F123", fn conn ->
        assert conn.request_path == "/v2/subscribers/org%2F123"
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _} = Subscribers.get_subscriber("org/123")
    end
  end

  describe "search_subscribers/1" do
    test "creates a GET to /v2/subscribers", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/subscribers", fn conn ->
        novu_response(conn, 200, %{data: [], next: nil, previous: nil})
      end)

      assert {:ok, _body} = Subscribers.search_subscribers()
    end

    for {opt, key, value} <- [
          {:after, "after", "cursor-a"},
          {:before, "before", "cursor-b"},
          {:limit, "limit", 25},
          {:order_direction, "orderDirection", "DESC"},
          {:order_by, "orderBy", "createdAt"},
          {:include_cursor, "includeCursor", true},
          {:email, "email", "test@example.com"},
          {:name, "name", "Jane"},
          {:phone, "phone", "+15551234567"},
          {:subscriber_id, "subscriberId", "example-id"}
        ] do
      test "supports optional #{opt}", %{bypass: bypass} do
        key = unquote(key)
        expected = to_string(unquote(value))

        Bypass.expect(bypass, "GET", "/v2/subscribers", fn conn ->
          assert %{^key => ^expected} = conn.query_params
          novu_response(conn, 200, %{data: []})
        end)

        assert {:ok, _body} = Subscribers.search_subscribers([{unquote(opt), unquote(value)}])
      end
    end
  end

  describe "get_subscribers/1 (deprecated)" do
    test "delegates to GET /v2/subscribers and forwards limit but not page", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/subscribers", fn conn ->
        assert %{"limit" => "5"} = conn.query_params
        refute Map.has_key?(conn.query_params, "page")
        novu_response(conn, 200, %{data: []})
      end)

      # credo:disable-for-next-line Credo.Check.Refactor.Apply
      assert {:ok, _body} = apply(Subscribers, :get_subscribers, [[limit: 5, page: 2]])
    end
  end

  describe "create_subscriber/2" do
    test "creates a POST to /v2/subscribers", %{bypass: bypass} do
      subscriber_id = "example-id"

      Bypass.expect(bypass, "POST", "/v2/subscribers", fn conn ->
        assert %{"subscriberId" => ^subscriber_id} = read_json_body(conn)
        assert conn.query_string == ""
        novu_response(conn, 201, %{data: %{subscriberId: subscriber_id}})
      end)

      assert {:ok, _body} = Subscribers.create_subscriber(subscriber_id)
    end

    for {opt, key, value} <- [
          {:email, "email", "test@example.com"},
          {:first_name, "firstName", "test"},
          {:last_name, "lastName", "user"},
          {:phone, "phone", "+15551234567"},
          {:avatar, "avatar", "https://i.pravatar.cc/150"},
          {:locale, "locale", "en_US"},
          {:timezone, "timezone", "America/New_York"},
          {:data, "data", %{"plan" => "pro"}}
        ] do
      test "supports optional #{opt}", %{bypass: bypass} do
        key = unquote(key)
        value = unquote(Macro.escape(value))

        Bypass.expect(bypass, "POST", "/v2/subscribers", fn conn ->
          assert %{"subscriberId" => "example-id", ^key => ^value} = read_json_body(conn)
          novu_response(conn, 201, %{data: %{subscriberId: "example-id"}})
        end)

        assert {:ok, _body} = Subscribers.create_subscriber("example-id", [{unquote(opt), value}])
      end
    end

    test "supports fail_if_exists as a query param", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v2/subscribers", fn conn ->
        assert %{"failIfExists" => "true"} = conn.query_params
        refute Map.has_key?(read_json_body(conn), "failIfExists")
        novu_response(conn, 201, %{data: %{subscriberId: "example-id"}})
      end)

      assert {:ok, _body} = Subscribers.create_subscriber("example-id", fail_if_exists: true)
    end
  end

  describe "get_subscriber/1" do
    test "creates a GET to /v2/subscribers/{subscriberId}", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/subscribers/example-id", fn conn ->
        novu_response(conn, 200, %{data: %{subscriberId: "example-id"}})
      end)

      assert {:ok, _body} = Subscribers.get_subscriber("example-id")
    end
  end

  describe "update_subscriber/2" do
    test "creates a PATCH to /v2/subscribers/{subscriberId}", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v2/subscribers/example-id", fn conn ->
        assert %{} == read_json_body(conn)
        novu_response(conn, 200, %{data: %{subscriberId: "example-id"}})
      end)

      assert {:ok, _body} = Subscribers.update_subscriber("example-id")
    end

    for {opt, key, value} <- [
          {:email, "email", "test@example.com"},
          {:first_name, "firstName", "test"},
          {:last_name, "lastName", "user"},
          {:phone, "phone", "+15551234567"},
          {:avatar, "avatar", "https://i.pravatar.cc/150"},
          {:locale, "locale", "en_US"},
          {:timezone, "timezone", "America/New_York"},
          {:data, "data", %{"plan" => "pro"}}
        ] do
      test "supports optional #{opt}", %{bypass: bypass} do
        key = unquote(key)
        value = unquote(Macro.escape(value))

        Bypass.expect(bypass, "PATCH", "/v2/subscribers/example-id", fn conn ->
          assert %{^key => ^value} = read_json_body(conn)
          novu_response(conn, 200, %{data: %{subscriberId: "example-id"}})
        end)

        assert {:ok, _body} = Subscribers.update_subscriber("example-id", [{unquote(opt), value}])
      end
    end
  end

  describe "delete_subscriber/1" do
    test "creates a DELETE to /v2/subscribers/{subscriberId}", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v2/subscribers/example-id", fn conn ->
        novu_response(conn, 200, %{acknowledged: true, status: "deleted"})
      end)

      assert {:ok, _body} = Subscribers.delete_subscriber("example-id")
    end
  end

  describe "bulk_create_subscribers/1" do
    test "creates a POST to /v1/subscribers/bulk with subscribers", %{bypass: bypass} do
      subscribers = [%{subscriberId: "a", email: "a@example.com"}, %{subscriberId: "b"}]

      Bypass.expect(bypass, "POST", "/v1/subscribers/bulk", fn conn ->
        assert %{"subscribers" => [%{"subscriberId" => "a", "email" => "a@example.com"}, %{"subscriberId" => "b"}]} =
                 read_json_body(conn)

        novu_response(conn, 201, %{data: %{created: [], updated: [], failed: []}})
      end)

      assert {:ok, _body} = Subscribers.bulk_create_subscribers(subscribers)
    end
  end

  describe "update_subscriber_online_status/2" do
    test "creates a PATCH to /v1/subscribers/{subscriberId}/online-status", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v1/subscribers/example-id/online-status", fn conn ->
        assert %{"isOnline" => false} = read_json_body(conn)
        novu_response(conn, 200, %{data: %{subscriberId: "example-id"}})
      end)

      assert {:ok, _body} = Subscribers.update_subscriber_online_status("example-id", false)
    end
  end

  for {fun, method} <- [update_subscriber_credentials: "PUT", upsert_subscriber_credentials: "PATCH"] do
    describe "#{fun}/3" do
      test "creates a #{method} to /v1/subscribers/{subscriberId}/credentials", %{bypass: bypass} do
        Bypass.expect(bypass, unquote(method), "/v1/subscribers/example-id/credentials", fn conn ->
          assert %{"providerId" => "fcm", "credentials" => %{}} = read_json_body(conn)
          novu_response(conn, 200, %{data: %{subscriberId: "example-id"}})
        end)

        assert {:ok, _body} = apply(Subscribers, unquote(fun), ["example-id", "fcm"])
      end

      for {opt, key, value} <- [
            {:webhook_url, "webhookUrl", "https://example.com/webhooks"},
            {:channel, "channel", "#general"},
            {:device_tokens, "deviceTokens", ["abc", "123"]},
            {:alert_uid, "alertUid", "alert-1"},
            {:title, "title", "Title"},
            {:image_url, "imageUrl", "https://example.com/i.png"},
            {:state, "state", "open"},
            {:external_url, "externalUrl", "https://example.com/x"}
          ] do
        test "supports optional #{opt}", %{bypass: bypass} do
          key = unquote(key)
          value = unquote(value)

          Bypass.expect(bypass, unquote(method), "/v1/subscribers/example-id/credentials", fn conn ->
            assert %{"providerId" => "fcm", "credentials" => %{^key => ^value}} = read_json_body(conn)
            novu_response(conn, 200, %{data: %{subscriberId: "example-id"}})
          end)

          assert {:ok, _body} = apply(Subscribers, unquote(fun), ["example-id", "fcm", [{unquote(opt), value}]])
        end
      end

      test "supports optional integration_identifier at the top level", %{bypass: bypass} do
        Bypass.expect(bypass, unquote(method), "/v1/subscribers/example-id/credentials", fn conn ->
          body = read_json_body(conn)
          assert %{"integrationIdentifier" => "my-fcm", "providerId" => "fcm"} = body
          refute Map.has_key?(body["credentials"], "integrationIdentifier")
          novu_response(conn, 200, %{data: %{subscriberId: "example-id"}})
        end)

        assert {:ok, _body} =
                 apply(Subscribers, unquote(fun), ["example-id", "fcm", [integration_identifier: "my-fcm"]])
      end
    end
  end

  describe "delete_subscriber_credentials/2" do
    test "creates a DELETE to /v1/subscribers/{subscriberId}/credentials/{providerId}", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/subscribers/example-id/credentials/fcm", fn conn ->
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, _body} = Subscribers.delete_subscriber_credentials("example-id", "fcm")
    end

    test "escapes the provider id", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/subscribers/example-id/credentials/a%2Fb", fn conn ->
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, _body} = Subscribers.delete_subscriber_credentials("example-id", "a/b")
    end
  end

  describe "get_subscriber_preferences/1" do
    test "creates a GET to /v1/subscribers/{subscriberId}/preferences", %{bypass: bypass} do
      subscriber_id = "example-id"

      Bypass.expect(bypass, "GET", "/v1/subscribers/#{URI.encode(subscriber_id)}/preferences", fn conn ->
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _body} = Subscribers.get_subscriber_preferences(subscriber_id)
    end
  end

  describe "update_subscriber_preferences/4" do
    test "creates a PATCH to /v1/subscribers/{subscriberId}/preferences/{templateId}", %{bypass: bypass} do
      subscriber_id = "example-id"
      template_id = "template-id"
      type = "in_app"
      enabled = false

      Bypass.expect(
        bypass,
        "PATCH",
        "/v1/subscribers/#{URI.encode(subscriber_id)}/preferences/#{template_id}",
        fn conn ->
          assert %{"channel" => %{"type" => ^type, "enabled" => ^enabled}} = read_json_body(conn)
          novu_response(conn, 200, %{data: []})
        end
      )

      assert {:ok, _body} = Subscribers.update_subscriber_preferences(subscriber_id, template_id, type, enabled)
    end
  end

  describe "get_notification_feed/2" do
    test "creates a GET to /v1/subscribers/{subscriberId}/notifications/feed", %{bypass: bypass} do
      subscriber_id = "example-id"

      Bypass.expect(bypass, "GET", "/v1/subscribers/#{URI.encode(subscriber_id)}/notifications/feed", fn conn ->
        assert %{"page" => "0"} = conn.query_params
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _body} = Subscribers.get_notification_feed(subscriber_id)
    end

    test "supports optional page", %{bypass: bypass} do
      subscriber_id = "example-id"
      page = 2

      Bypass.expect(bypass, "GET", "/v1/subscribers/#{URI.encode(subscriber_id)}/notifications/feed", fn conn ->
        page_param = to_string(page)
        assert %{"page" => ^page_param} = conn.query_params
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _body} = Subscribers.get_notification_feed(subscriber_id, page: page)
    end

    test "supports optional feed_identifier", %{bypass: bypass} do
      subscriber_id = "example-id"
      feed_identifier = "feed-id"

      Bypass.expect(bypass, "GET", "/v1/subscribers/#{URI.encode(subscriber_id)}/notifications/feed", fn conn ->
        assert %{"page" => "0", "feedIdentifier" => ^feed_identifier} = conn.query_params
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _body} = Subscribers.get_notification_feed(subscriber_id, feed_identifier: feed_identifier)
    end

    test "supports optional seen", %{bypass: bypass} do
      subscriber_id = "example-id"
      seen = false

      Bypass.expect(bypass, "GET", "/v1/subscribers/#{URI.encode(subscriber_id)}/notifications/feed", fn conn ->
        seen_param = to_string(seen)
        assert %{"page" => "0", "seen" => ^seen_param} = conn.query_params
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _body} = Subscribers.get_notification_feed(subscriber_id, seen: seen)
    end
  end

  describe "get_unseen_count/2" do
    test "creates a GET to /v1/subscribers/{subscriberId}/notifications/unseen", %{bypass: bypass} do
      subscriber_id = "example-id"

      Bypass.expect(bypass, "GET", "/v1/subscribers/#{URI.encode(subscriber_id)}/notifications/unseen", fn conn ->
        novu_response(conn, 200, %{data: %{"count" => 0}})
      end)

      assert {:ok, _body} = Subscribers.get_unseen_count(subscriber_id)
    end

    test "supports optional seen", %{bypass: bypass} do
      subscriber_id = "example-id"
      seen = true

      Bypass.expect(bypass, "GET", "/v1/subscribers/#{URI.encode(subscriber_id)}/notifications/unseen", fn conn ->
        seen_param = to_string(seen)
        assert %{"seen" => ^seen_param} = conn.query_params
        novu_response(conn, 200, %{data: %{"count" => 0}})
      end)

      assert {:ok, _body} = Subscribers.get_unseen_count(subscriber_id, seen: seen)
    end
  end

  describe "mark_message_as_seen/2" do
    test "creates a POST to /v1/subscribers/{subscriberId}/messages/{messageId}/seen", %{bypass: bypass} do
      subscriber_id = "example-id"
      message_id = "message-id"

      Bypass.expect(
        bypass,
        "POST",
        "/v1/subscribers/#{URI.encode(subscriber_id)}/messages/#{message_id}/seen",
        fn conn ->
          novu_response(conn, 201, %{data: %{"seen" => true}})
        end
      )

      assert {:ok, _body} = Subscribers.mark_message_as_seen(subscriber_id, message_id)
    end
  end

  describe "mark_action_as_seen/3" do
    test "creates a POST to /v1/subscribers/{subscriberId}/messages/{messageId}/actions/{type}", %{bypass: bypass} do
      subscriber_id = "example-id"
      message_id = "message-id"
      type = "secondary"

      Bypass.expect(
        bypass,
        "POST",
        "/v1/subscribers/#{URI.encode(subscriber_id)}/messages/#{message_id}/actions/#{type}",
        fn conn ->
          novu_response(conn, 201, %{data: %{"seen" => true}})
        end
      )

      assert {:ok, _body} = Subscribers.mark_action_as_seen(subscriber_id, message_id, type)
    end
  end
end
