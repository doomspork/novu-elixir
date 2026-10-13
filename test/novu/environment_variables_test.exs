defmodule Novu.EnvironmentVariablesTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.EnvironmentVariables

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

  describe "list_environment_variables/1" do
    test "creates a GET to /v1/environment-variables", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/environment-variables", fn conn ->
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = EnvironmentVariables.list_environment_variables()
    end

    test "sends search as a query param", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/environment-variables", fn conn ->
        assert conn.query_params["search"] == "BASE"
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = EnvironmentVariables.list_environment_variables(search: "BASE")
    end
  end

  describe "create_environment_variable/2" do
    test "creates a POST with the key", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v1/environment-variables", fn conn ->
        assert read_json_body(conn) == %{"key" => "BASE_URL"}
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _} = EnvironmentVariables.create_environment_variable("BASE_URL")
    end

    test "sends type, isSecret and values", %{bypass: bypass} do
      values = [%{"_environmentId" => "env-1", "value" => "v"}]

      Bypass.expect(bypass, "POST", "/v1/environment-variables", fn conn ->
        body = read_json_body(conn)
        assert body["key"] == "API_TOKEN"
        assert body["type"] == "string"
        assert body["isSecret"] == true
        assert body["values"] == values
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _} =
               EnvironmentVariables.create_environment_variable("API_TOKEN",
                 type: "string",
                 is_secret: true,
                 values: values
               )
    end
  end

  describe "get_environment_variable/1" do
    test "creates a GET to the variable path", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/environment-variables/BASE_URL", fn conn ->
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _} = EnvironmentVariables.get_environment_variable("BASE_URL")
    end

    test "escapes the key", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/environment-variables/a%2Fb", fn conn ->
        assert conn.request_path == "/v1/environment-variables/a%2Fb"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = EnvironmentVariables.get_environment_variable("a/b")
    end
  end

  describe "update_environment_variable/2" do
    test "creates a PATCH to the variable path", %{bypass: bypass} do
      Bypass.expect(bypass, "PATCH", "/v1/environment-variables/BASE_URL", fn conn ->
        assert read_json_body(conn) == %{}
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _} = EnvironmentVariables.update_environment_variable("BASE_URL")
    end

    test "sends key, type, isSecret and values", %{bypass: bypass} do
      values = [%{"_environmentId" => "env-1", "value" => "v"}]

      Bypass.expect(bypass, "PATCH", "/v1/environment-variables/BASE_URL", fn conn ->
        body = read_json_body(conn)
        assert body["key"] == "NEW_URL"
        assert body["type"] == "string"
        assert body["isSecret"] == false
        assert body["values"] == values
        novu_response(conn, 200, %{data: %{}})
      end)

      assert {:ok, _} =
               EnvironmentVariables.update_environment_variable("BASE_URL",
                 key: "NEW_URL",
                 type: "string",
                 is_secret: false,
                 values: values
               )
    end
  end

  describe "delete_environment_variable/1" do
    test "creates a DELETE to the variable path", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v1/environment-variables/BASE_URL", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = EnvironmentVariables.delete_environment_variable("BASE_URL")
    end
  end

  describe "get_environment_variable_usage/1" do
    test "creates a GET to the usage path", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/environment-variables/BASE_URL/usage", fn conn ->
        novu_response(conn, 200, %{data: %{workflows: []}})
      end)

      assert {:ok, _} = EnvironmentVariables.get_environment_variable_usage("BASE_URL")
    end
  end
end
