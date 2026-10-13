defmodule Novu.MessagesTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Messages

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

  describe "get_messages/1" do
    test "creates a GET to /v1/messages", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/messages", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{page: 0, totalCount: 0, pageSize: 10, data: []})
      end)

      assert {:ok, _body} = Messages.get_messages()
    end

    test "sends scalar filters as camelCase query params", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/messages", fn conn ->
        assert conn.query_params["channel"] == "email"
        assert conn.query_params["subscriberId"] == "sub-1"
        assert conn.query_params["transactionId"] == "tx-1"
        assert conn.query_params["page"] == "2"
        assert conn.query_params["limit"] == "5"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Messages.get_messages(
                 channel: "email",
                 subscriber_id: "sub-1",
                 transaction_id: "tx-1",
                 page: 2,
                 limit: 5
               )
    end

    test "sends list transaction_id and context_keys as repeated keys", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/messages", fn conn ->
        assert conn.query_string =~ "transactionId=a&transactionId=b"
        assert conn.query_string =~ "contextKeys=tenant%3A1&contextKeys=org%3A2"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Messages.get_messages(transaction_id: ["a", "b"], context_keys: ["tenant:1", "org:2"])
    end
  end

  describe "delete_message/1" do
    test "creates a DELETE to /v1/messages/{messageId}", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/messages/example-id", fn conn ->
        novu_response(conn, 200, %{acknowledged: true, status: "deleted"})
      end)

      assert {:ok, _body} = Messages.delete_message("example-id")
    end

    test "escapes the message id", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/messages/a%2Fb", fn conn ->
        assert conn.request_path == "/v1/messages/a%2Fb"
        novu_response(conn, 200, %{acknowledged: true, status: "deleted"})
      end)

      assert {:ok, _body} = Messages.delete_message("a/b")
    end
  end

  describe "delete_messages/1" do
    @tag :capture_log
    test "delegates to delete_message/1", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/messages/example-id", fn conn ->
        novu_response(conn, 200, %{acknowledged: true, status: "deleted"})
      end)

      # dynamic call avoids the compile-time deprecation warning
      deprecated = Function.capture(Messages, :delete_messages, 1)
      assert {:ok, _body} = deprecated.("example-id")
    end
  end

  describe "delete_messages_by_transaction_id/2" do
    test "creates a DELETE to /v1/messages/transaction/{transactionId}", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/messages/transaction/tx-1", fn conn ->
        assert conn.query_string == ""
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _body} = Messages.delete_messages_by_transaction_id("tx-1")
    end

    test "sends channel as a query param", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/messages/transaction/tx-1", fn conn ->
        assert conn.query_params["channel"] == "sms"
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _body} = Messages.delete_messages_by_transaction_id("tx-1", channel: "sms")
    end

    test "escapes the transaction id", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/messages/transaction/a%2Fb", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _body} = Messages.delete_messages_by_transaction_id("a/b")
    end
  end
end
