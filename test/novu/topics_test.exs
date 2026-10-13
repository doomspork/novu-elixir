defmodule Novu.TopicsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Topics

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

  describe "list_topics/1" do
    test "creates a GET to /v2/topics", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/topics", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{data: [], next: nil, previous: nil})
      end)

      assert {:ok, _} = Topics.list_topics()
    end

    test "sends all filters as query params", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/topics", fn conn ->
        assert conn.query_params == %{
                 "after" => "a",
                 "before" => "b",
                 "limit" => "10",
                 "orderDirection" => "DESC",
                 "orderBy" => "createdAt",
                 "includeCursor" => "true",
                 "key" => "k",
                 "name" => "n"
               }

        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Topics.list_topics(
                 after: "a",
                 before: "b",
                 limit: 10,
                 order_direction: "DESC",
                 order_by: "createdAt",
                 include_cursor: true,
                 key: "k",
                 name: "n"
               )
    end
  end

  describe "create_topic/2" do
    test "creates a POST to /v2/topics with the key", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v2/topics", fn conn ->
        assert read_json_body(conn) == %{"key" => "my-topic"}
        assert conn.query_string == ""
        novu_response(conn, 201, %{key: "my-topic"})
      end)

      assert {:ok, _} = Topics.create_topic("my-topic")
    end

    test "sends name and data in the body", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v2/topics", fn conn ->
        body = read_json_body(conn)
        assert body["name"] == "My Topic"
        assert body["data"] == %{"priority" => 1}
        novu_response(conn, 201, %{key: "my-topic"})
      end)

      assert {:ok, _} = Topics.create_topic("my-topic", name: "My Topic", data: %{priority: 1})
    end

    test "sends fail_if_exists as failIfExists query param", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v2/topics", fn conn ->
        assert conn.query_params["failIfExists"] == "true"
        refute Map.has_key?(read_json_body(conn), "failIfExists")
        novu_response(conn, 201, %{key: "my-topic"})
      end)

      assert {:ok, _} = Topics.create_topic("my-topic", fail_if_exists: true)
    end
  end

  describe "get_topic/1" do
    test "creates a GET to /v2/topics/:key", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/topics/my-topic", fn conn ->
        novu_response(conn, 200, %{key: "my-topic"})
      end)

      assert {:ok, _} = Topics.get_topic("my-topic")
    end

    test "escapes the key", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/topics/a%2Fb", fn conn ->
        assert conn.request_path == "/v2/topics/a%2Fb"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Topics.get_topic("a/b")
    end
  end

  describe "update_topic/2" do
    test "creates a PATCH to /v2/topics/:key with name and data", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v2/topics/my-topic", fn conn ->
        body = read_json_body(conn)
        assert body["name"] == "New"
        assert body["data"] == %{"a" => "b"}
        novu_response(conn, 200, %{key: "my-topic"})
      end)

      assert {:ok, _} = Topics.update_topic("my-topic", name: "New", data: %{a: "b"})
    end
  end

  describe "delete_topic/1" do
    test "creates a DELETE to /v2/topics/:key", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/v2/topics/my-topic", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Topics.delete_topic("my-topic")
    end
  end

  describe "list_topic_subscriptions/2" do
    test "creates a GET to /v2/topics/:key/subscriptions", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/topics/my-topic/subscriptions", fn conn ->
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = Topics.list_topic_subscriptions("my-topic")
    end

    test "sends pagination, subscriberId and repeated contextKeys", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/topics/my-topic/subscriptions", fn conn ->
        assert conn.query_params["limit"] == "5"
        assert conn.query_params["after"] == "x"
        assert conn.query_params["subscriberId"] == "sub-1"
        assert conn.query_string =~ "contextKeys=tenant%3Aacme&contextKeys=app%3Aweb"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Topics.list_topic_subscriptions("my-topic",
                 limit: 5,
                 after: "x",
                 subscriber_id: "sub-1",
                 context_keys: ["tenant:acme", "app:web"]
               )
    end
  end

  describe "create_topic_subscriptions/3" do
    test "creates a POST with subscriptions as ids", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v2/topics/my-topic/subscriptions", fn conn ->
        assert read_json_body(conn) == %{"subscriptions" => ["a", "b"]}
        novu_response(conn, 201, %{data: []})
      end)

      assert {:ok, _} = Topics.create_topic_subscriptions("my-topic", ["a", "b"])
    end

    test "sends maps, name, context and preferences", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v2/topics/my-topic/subscriptions", fn conn ->
        body = read_json_body(conn)
        assert body["subscriptions"] == [%{"identifier" => "i1", "subscriberId" => "s1"}]
        assert body["name"] == "Topic"
        assert body["context"] == %{"tenant" => "acme"}
        assert body["preferences"] == ["wf-1"]
        novu_response(conn, 201, %{data: []})
      end)

      assert {:ok, _} =
               Topics.create_topic_subscriptions("my-topic", [%{identifier: "i1", subscriberId: "s1"}],
                 name: "Topic",
                 context: %{tenant: "acme"},
                 preferences: ["wf-1"]
               )
    end
  end

  describe "delete_topic_subscriptions/2" do
    test "creates a DELETE with a JSON body", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/v2/topics/my-topic/subscriptions", fn conn ->
        assert read_json_body(conn) == %{"subscriptions" => ["a", %{"identifier" => "i1"}]}
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = Topics.delete_topic_subscriptions("my-topic", ["a", %{identifier: "i1"}])
    end
  end

  describe "get_topic_subscription/2" do
    test "creates a GET to the subscription path", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/topics/my-topic/subscriptions/ident-1", fn conn ->
        novu_response(conn, 200, %{identifier: "ident-1"})
      end)

      assert {:ok, _} = Topics.get_topic_subscription("my-topic", "ident-1")
    end
  end

  describe "update_topic_subscription/3" do
    test "creates a PATCH with name and preferences", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v2/topics/my-topic/subscriptions/ident-1", fn conn ->
        body = read_json_body(conn)
        assert body["name"] == "Sub"
        assert body["preferences"] == ["wf-1"]
        novu_response(conn, 200, %{identifier: "ident-1"})
      end)

      assert {:ok, _} = Topics.update_topic_subscription("my-topic", "ident-1", name: "Sub", preferences: ["wf-1"])
    end
  end

  describe "check_topic_subscriber/2" do
    test "creates a GET to /v1/topics/:key/subscribers/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/topics/my-topic/subscribers/sub-1", fn conn ->
        novu_response(conn, 200, %{topicKey: "my-topic", externalSubscriberId: "sub-1"})
      end)

      assert {:ok, _} = Topics.check_topic_subscriber("my-topic", "sub-1")
    end
  end
end
