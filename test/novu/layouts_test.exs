defmodule Novu.LayoutsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Layouts

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
    test "layout id containing a slash is escaped", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/layouts/a%2Fb", fn conn ->
        assert conn.request_path == "/v2/layouts/a%2Fb"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Layouts.get_layout("a/b")
    end
  end

  describe "list_layouts/1" do
    test "creates a GET to /v2/layouts", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/layouts", fn conn ->
        novu_response(conn, 200, %{layouts: [], totalCount: 0})
      end)

      assert {:ok, _} = Layouts.list_layouts()
    end

    test "supports query options", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/layouts", fn conn ->
        assert %{
                 "limit" => "10",
                 "offset" => "5",
                 "orderDirection" => "ASC",
                 "orderBy" => "name",
                 "query" => "main"
               } = conn.query_params

        novu_response(conn, 200, %{layouts: []})
      end)

      assert {:ok, _} =
               Layouts.list_layouts(limit: 10, offset: 5, order_direction: "ASC", order_by: "name", query: "main")
    end
  end

  describe "create_layout/1" do
    test "creates a POST to /v2/layouts", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v2/layouts", fn conn ->
        assert %{"layoutId" => "main", "name" => "Main", "isTranslationEnabled" => true} = read_json_body(conn)
        novu_response(conn, 201, %{layoutId: "main"})
      end)

      assert {:ok, _} = Layouts.create_layout(%{layoutId: "main", name: "Main", isTranslationEnabled: true})
    end
  end

  describe "get_layout/1" do
    test "creates a GET to /v2/layouts/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/layouts/main", fn conn ->
        novu_response(conn, 200, %{layoutId: "main"})
      end)

      assert {:ok, _} = Layouts.get_layout("main")
    end
  end

  describe "update_layout/2" do
    test "creates a PUT to /v2/layouts/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "PUT", "/v2/layouts/main", fn conn ->
        assert %{"name" => "New", "isTranslationEnabled" => false, "controlValues" => %{"x" => 1}} =
                 read_json_body(conn)

        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} =
               Layouts.update_layout("main", %{name: "New", isTranslationEnabled: false, controlValues: %{x: 1}})
    end
  end

  describe "delete_layout/1" do
    test "creates a DELETE to /v2/layouts/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v2/layouts/main", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Layouts.delete_layout("main")
    end
  end

  describe "duplicate_layout/2" do
    test "creates a POST to /v2/layouts/:id/duplicate", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v2/layouts/main/duplicate", fn conn ->
        assert %{"name" => "Copy", "layoutId" => "copy", "isTranslationEnabled" => true} = read_json_body(conn)
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} = Layouts.duplicate_layout("main", %{name: "Copy", layoutId: "copy", isTranslationEnabled: true})
    end
  end

  describe "preview_layout/2" do
    test "creates a POST to /v2/layouts/:id/preview", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v2/layouts/main/preview", fn conn ->
        assert %{"controlValues" => %{"a" => 1}, "previewPayload" => %{"subscriber" => %{}}} = read_json_body(conn)
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} = Layouts.preview_layout("main", %{controlValues: %{a: 1}, previewPayload: %{subscriber: %{}}})
    end
  end

  describe "get_layout_usage/1" do
    test "creates a GET to /v2/layouts/:id/usage", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/layouts/main/usage", fn conn ->
        novu_response(conn, 200, %{workflows: []})
      end)

      assert {:ok, _} = Layouts.get_layout_usage("main")
    end
  end
end
