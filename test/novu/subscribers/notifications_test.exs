defmodule Novu.Subscribers.NotificationsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Subscribers.Notifications

  @test_api_key "test-api-key"
  @base "/v2/subscribers/sub-1/notifications"

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
    test "subscriber and notification ids are escaped", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v2/subscribers/a%2Fb/notifications/c%2Fd/read", fn conn ->
        assert conn.request_path == "/v2/subscribers/a%2Fb/notifications/c%2Fd/read"
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _} = Notifications.mark_as_read("a/b", "c/d")
    end
  end

  describe "list/2" do
    test "creates a GET to the notifications path", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @base, fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = Notifications.list("sub-1")
    end

    test "sends scalar filters as query params", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @base, fn conn ->
        assert %{
                 "limit" => "10",
                 "after" => "cur",
                 "offset" => "5",
                 "read" => "true",
                 "archived" => "false",
                 "snoozed" => "false",
                 "seen" => "true",
                 "createdGte" => "100",
                 "createdLte" => "200"
               } = conn.query_params

        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Notifications.list("sub-1",
                 limit: 10,
                 after: "cur",
                 offset: 5,
                 read: true,
                 archived: false,
                 snoozed: false,
                 seen: true,
                 created_gte: 100,
                 created_lte: 200
               )
    end

    test "JSON-encodes data map", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @base, fn conn ->
        assert Jason.decode!(conn.query_params["data"]) == %{"a" => 1}
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = Notifications.list("sub-1", data: %{a: 1})
    end

    test "sends severity and contextKeys as repeated keys", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @base, fn conn ->
        assert conn.query_string == "severity=high&severity=low&contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = Notifications.list("sub-1", severity: ["high", "low"], context_keys: ["a", "b"])
    end
  end

  describe "count/2" do
    test "JSON-encodes filters into the query", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", @base <> "/count", fn conn ->
        assert Jason.decode!(conn.query_params["filters"]) == [%{"read" => false}]
        novu_response(conn, 200, %{data: %{counts: []}})
      end)

      assert {:ok, _} = Notifications.count("sub-1", [%{read: false}])
    end
  end

  describe "mark_all_as_read/2" do
    test "creates a POST to /read", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/read", fn conn ->
        assert read_json_body(conn) == %{}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Notifications.mark_all_as_read("sub-1")
    end

    test "sends optional fields", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/read", fn conn ->
        assert %{
                 "tags" => ["t"],
                 "data" => data,
                 "contextKeys" => ["ctx"]
               } = read_json_body(conn)

        assert Jason.decode!(data) == %{"a" => 1}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} =
               Notifications.mark_all_as_read("sub-1",
                 tags: ["t"],
                 data: %{a: 1},
                 context_keys: ["ctx"]
               )
    end
  end

  describe "archive_all/2" do
    test "creates a POST to /archive", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/archive", fn conn ->
        assert read_json_body(conn) == %{}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Notifications.archive_all("sub-1")
    end

    test "sends optional fields", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/archive", fn conn ->
        assert %{
                 "tags" => ["t"],
                 "data" => data,
                 "contextKeys" => ["ctx"]
               } = read_json_body(conn)

        assert Jason.decode!(data) == %{"a" => 1}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} =
               Notifications.archive_all("sub-1",
                 tags: ["t"],
                 data: %{a: 1},
                 context_keys: ["ctx"]
               )
    end
  end

  describe "archive_all_read/2" do
    test "creates a POST to /read-archive", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/read-archive", fn conn ->
        assert read_json_body(conn) == %{}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Notifications.archive_all_read("sub-1")
    end

    test "sends optional fields", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/read-archive", fn conn ->
        assert %{
                 "tags" => ["t"],
                 "data" => data,
                 "contextKeys" => ["ctx"]
               } = read_json_body(conn)

        assert Jason.decode!(data) == %{"a" => 1}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} =
               Notifications.archive_all_read("sub-1",
                 tags: ["t"],
                 data: %{a: 1},
                 context_keys: ["ctx"]
               )
    end
  end

  describe "delete_all/2" do
    test "creates a POST to /delete", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/delete", fn conn ->
        assert read_json_body(conn) == %{}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Notifications.delete_all("sub-1")
    end

    test "sends optional fields", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/delete", fn conn ->
        assert %{
                 "tags" => ["t"],
                 "data" => data,
                 "contextKeys" => ["ctx"]
               } = read_json_body(conn)

        assert Jason.decode!(data) == %{"a" => 1}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} =
               Notifications.delete_all("sub-1",
                 tags: ["t"],
                 data: %{a: 1},
                 context_keys: ["ctx"]
               )
    end
  end

  describe "mark_as_seen/2" do
    test "creates a POST to /seen", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/seen", fn conn ->
        assert read_json_body(conn) == %{}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Notifications.mark_as_seen("sub-1")
    end

    test "sends optional fields", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", @base <> "/seen", fn conn ->
        assert %{
                 "notificationIds" => ["n1", "n2"],
                 "tags" => ["t"],
                 "data" => data,
                 "contextKeys" => ["ctx"]
               } = read_json_body(conn)

        assert Jason.decode!(data) == %{"a" => 1}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} =
               Notifications.mark_as_seen("sub-1",
                 notification_ids: ["n1", "n2"],
                 tags: ["t"],
                 data: %{a: 1},
                 context_keys: ["ctx"]
               )
    end
  end

  describe "delete/3" do
    test "creates a DELETE with contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", @base <> "/n1", fn conn ->
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Notifications.delete("sub-1", "n1", context_keys: ["a", "b"])
    end

    test "works without options", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", @base <> "/n1", fn conn ->
        assert conn.query_string == ""
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Notifications.delete("sub-1", "n1")
    end
  end

  describe "mark_as_read/3" do
    test "creates a PATCH to /read", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/read", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.mark_as_read("sub-1", "n1")
    end

    test "sends contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/read", fn conn ->
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.mark_as_read("sub-1", "n1", context_keys: ["a", "b"])
    end
  end

  describe "mark_as_unread/3" do
    test "creates a PATCH to /unread", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/unread", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.mark_as_unread("sub-1", "n1")
    end

    test "sends contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/unread", fn conn ->
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.mark_as_unread("sub-1", "n1", context_keys: ["a", "b"])
    end
  end

  describe "archive/3" do
    test "creates a PATCH to /archive", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/archive", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.archive("sub-1", "n1")
    end

    test "sends contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/archive", fn conn ->
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.archive("sub-1", "n1", context_keys: ["a", "b"])
    end
  end

  describe "unarchive/3" do
    test "creates a PATCH to /unarchive", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/unarchive", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.unarchive("sub-1", "n1")
    end

    test "sends contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/unarchive", fn conn ->
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.unarchive("sub-1", "n1", context_keys: ["a", "b"])
    end
  end

  describe "unsnooze/3" do
    test "creates a PATCH to /unsnooze", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/unsnooze", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.unsnooze("sub-1", "n1")
    end

    test "sends contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/unsnooze", fn conn ->
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.unsnooze("sub-1", "n1", context_keys: ["a", "b"])
    end
  end

  describe "snooze/4" do
    test "sends snoozeUntil string", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/snooze", fn conn ->
        assert read_json_body(conn) == %{"snoozeUntil" => "2030-01-01T00:00:00Z"}
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.snooze("sub-1", "n1", "2030-01-01T00:00:00Z")
    end

    test "encodes a DateTime and sends contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/snooze", fn conn ->
        assert read_json_body(conn) == %{"snoozeUntil" => "2030-01-01T00:00:00Z"}
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      {:ok, dt, _} = DateTime.from_iso8601("2030-01-01T00:00:00Z")
      assert {:ok, _} = Notifications.snooze("sub-1", "n1", dt, context_keys: ["a", "b"])
    end
  end

  describe "complete_action/4" do
    test "creates a PATCH to the action path", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/actions/primary/complete", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.complete_action("sub-1", "n1", "primary")
    end

    test "supports secondary and contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/actions/secondary/complete", fn conn ->
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.complete_action("sub-1", "n1", "secondary", context_keys: ["a", "b"])
    end
  end

  describe "revert_action/4" do
    test "creates a PATCH to the action path", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/actions/primary/revert", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.revert_action("sub-1", "n1", "primary")
    end

    test "supports secondary and contextKeys", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", @base <> "/n1/actions/secondary/revert", fn conn ->
        assert conn.query_string == "contextKeys=a&contextKeys=b"
        novu_response(conn, 200, %{data: %{id: "n1"}})
      end)

      assert {:ok, _} = Notifications.revert_action("sub-1", "n1", "secondary", context_keys: ["a", "b"])
    end
  end
end
