defmodule Novu.WorkflowsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Workflows

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
    test "workflow id containing a slash is escaped", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/workflows/a%2Fb", fn conn ->
        assert conn.request_path == "/v2/workflows/a%2Fb"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Workflows.get_workflow("a/b")
    end

    test "step id containing a slash is escaped", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/workflows/wf/steps/s%2F1", fn conn ->
        assert conn.request_path == "/v2/workflows/wf/steps/s%2F1"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Workflows.get_workflow_step("wf", "s/1")
    end
  end

  describe "list_workflows/1" do
    test "creates a GET to /v2/workflows", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/workflows", fn conn ->
        novu_response(conn, 200, %{workflows: [], totalCount: 0})
      end)

      assert {:ok, _} = Workflows.list_workflows()
    end

    test "supports scalar query options", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/workflows", fn conn ->
        assert %{
                 "limit" => "10",
                 "offset" => "5",
                 "orderDirection" => "DESC",
                 "orderBy" => "name",
                 "query" => "welcome"
               } = conn.query_params

        novu_response(conn, 200, %{workflows: []})
      end)

      assert {:ok, _} =
               Workflows.list_workflows(
                 limit: 10,
                 offset: 5,
                 order_direction: "DESC",
                 order_by: "name",
                 query: "welcome"
               )
    end

    test "supports list-valued tags as repeated keys", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/workflows", fn conn ->
        assert conn.query_string == "tags=a&tags=b"
        novu_response(conn, 200, %{workflows: []})
      end)

      assert {:ok, _} = Workflows.list_workflows(tags: ["a", "b"])
    end

    test "supports list-valued status as repeated keys", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/workflows", fn conn ->
        assert conn.query_string == "status=ACTIVE&status=ERROR"
        novu_response(conn, 200, %{workflows: []})
      end)

      assert {:ok, _} = Workflows.list_workflows(status: ["ACTIVE", "ERROR"])
    end
  end

  describe "create_workflow/1" do
    test "creates a POST to /v2/workflows with the body passed through", %{bypass: bypass} do
      attrs = %{
        name: "Welcome",
        workflowId: "welcome",
        steps: [%{name: "In-App", type: "in_app", controlValues: %{body: "Hi"}}]
      }

      Bypass.expect(bypass, "POST", "/v2/workflows", fn conn ->
        assert %{
                 "name" => "Welcome",
                 "workflowId" => "welcome",
                 "steps" => [%{"type" => "in_app"}]
               } = read_json_body(conn)

        novu_response(conn, 201, %{workflowId: "welcome"})
      end)

      assert {:ok, _} = Workflows.create_workflow(attrs)
    end
  end

  describe "get_workflow/2" do
    test "creates a GET to /v2/workflows/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/workflows/wf1", fn conn ->
        novu_response(conn, 200, %{workflowId: "wf1"})
      end)

      assert {:ok, _} = Workflows.get_workflow("wf1")
    end

    test "supports environment_id", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/workflows/wf1", fn conn ->
        assert %{"environmentId" => "env1"} = conn.query_params
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Workflows.get_workflow("wf1", environment_id: "env1")
    end
  end

  describe "update_workflow/2" do
    test "creates a PUT to /v2/workflows/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "PUT", "/v2/workflows/wf1", fn conn ->
        assert %{"name" => "N", "steps" => [], "preferences" => %{}} = read_json_body(conn)
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Workflows.update_workflow("wf1", %{name: "N", steps: [], preferences: %{}})
    end
  end

  describe "patch_workflow/2" do
    test "creates a PATCH to /v2/workflows/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v2/workflows/wf1", fn conn ->
        assert %{"active" => false, "tags" => ["x"]} = read_json_body(conn)
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Workflows.patch_workflow("wf1", %{active: false, tags: ["x"]})
    end
  end

  describe "delete_workflow/1" do
    test "creates a DELETE to /v2/workflows/:id", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v2/workflows/wf1", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Workflows.delete_workflow("wf1")
    end
  end

  describe "sync_workflow/2" do
    test "creates a PUT to /v2/workflows/:id/sync with targetEnvironmentId", %{bypass: bypass} do
      Bypass.expect(bypass, "PUT", "/v2/workflows/wf1/sync", fn conn ->
        assert %{"targetEnvironmentId" => "env2"} = read_json_body(conn)
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Workflows.sync_workflow("wf1", "env2")
    end
  end

  describe "get_workflow_step/2" do
    test "creates a GET to /v2/workflows/:id/steps/:step_id", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/workflows/wf1/steps/s1", fn conn ->
        novu_response(conn, 200, %{stepId: "s1"})
      end)

      assert {:ok, _} = Workflows.get_workflow_step("wf1", "s1")
    end
  end

  describe "preview_workflow_step/3" do
    test "creates a POST to /v2/workflows/:id/step/:step_id/preview", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v2/workflows/wf1/step/s1/preview", fn conn ->
        assert %{"controlValues" => %{"a" => 1}, "previewPayload" => %{"subscriber" => %{}}} = read_json_body(conn)
        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} =
               Workflows.preview_workflow_step("wf1", "s1", %{
                 controlValues: %{a: 1},
                 previewPayload: %{subscriber: %{}}
               })
    end
  end

  describe "duplicate_workflow/2" do
    test "creates a POST to /v2/workflows/:id/duplicate", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v2/workflows/wf1/duplicate", fn conn ->
        assert %{
                 "name" => "Copy",
                 "workflowId" => "copy",
                 "tags" => ["t"],
                 "description" => "d",
                 "isTranslationEnabled" => true
               } = read_json_body(conn)

        novu_response(conn, 201, %{})
      end)

      assert {:ok, _} =
               Workflows.duplicate_workflow("wf1", %{
                 name: "Copy",
                 workflowId: "copy",
                 tags: ["t"],
                 description: "d",
                 isTranslationEnabled: true
               })
    end
  end
end
