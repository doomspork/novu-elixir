defmodule Novu.TranslationsTest do
  use ExUnit.Case

  import Novu.ApiTestHelpers

  alias Novu.Translations

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

  # Parses a multipart request into a list of `{name, filename_or_nil, content}`.
  defp read_multipart(conn) do
    assert [content_type] = Plug.Conn.get_req_header(conn, "content-type")
    assert String.starts_with?(content_type, "multipart/form-data")

    [_, boundary] = Regex.run(~r/boundary=([^;]+)/, content_type)
    {:ok, body, _} = Plug.Conn.read_body(conn)

    body
    |> String.split("--" <> boundary)
    |> Enum.filter(&String.contains?(&1, "content-disposition"))
    |> Enum.map(fn part ->
      [headers, content] = String.split(part, "\r\n\r\n", parts: 2)
      [_, name] = Regex.run(~r/name="([^"]+)"/, headers)
      filename = with [_, f] <- Regex.run(~r/filename="([^"]+)"/, headers), do: f
      {name, filename, content |> String.trim_trailing("\r\n") |> String.trim_trailing("--")}
    end)
  end

  describe "create_translation/1" do
    test "creates a POST to /v2/translations with the attrs", %{bypass: bypass} do
      attrs = %{
        "resourceId" => "wf",
        "resourceType" => "workflow",
        "locale" => "en_US",
        "content" => %{"hello" => "Hello"}
      }

      Bypass.expect(bypass, "POST", "/v2/translations", fn conn ->
        assert read_json_body(conn) == attrs
        novu_response(conn, 200, %{locale: "en_US"})
      end)

      assert {:ok, _} = Translations.create_translation(attrs)
    end
  end

  describe "get_translation/3" do
    test "creates a GET to the translation path", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/translations/workflow/my-wf/en_US", fn conn ->
        novu_response(conn, 200, %{locale: "en_US"})
      end)

      assert {:ok, _} = Translations.get_translation("workflow", "my-wf", "en_US")
    end

    test "escapes path segments", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v2/translations/layout/a%2Fb/en_US", fn conn ->
        assert conn.request_path == "/v2/translations/layout/a%2Fb/en_US"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Translations.get_translation("layout", "a/b", "en_US")
    end
  end

  describe "delete_translation/3" do
    test "creates a DELETE to the translation path", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v2/translations/workflow/my-wf/en_US", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Translations.delete_translation("workflow", "my-wf", "en_US")
    end
  end

  describe "get_translation_group/2" do
    test "creates a GET to the group path", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/translations/group/workflow/my-wf", fn conn ->
        novu_response(conn, 200, %{locales: []})
      end)

      assert {:ok, _} = Translations.get_translation_group("workflow", "my-wf")
    end
  end

  describe "delete_translation_group/2" do
    test "creates a DELETE to the resource path", %{bypass: bypass} do
      Bypass.expect(bypass, "DELETE", "/v2/translations/layout/my-layout", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, _} = Translations.delete_translation_group("layout", "my-layout")
    end
  end

  describe "get_master_json/1" do
    test "creates a GET to /v2/translations/master-json", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/translations/master-json", fn conn ->
        assert conn.query_string == ""
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Translations.get_master_json()
    end

    test "sends locale as a query param", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/translations/master-json", fn conn ->
        assert conn.query_params["locale"] == "fr_FR"
        novu_response(conn, 200, %{})
      end)

      assert {:ok, _} = Translations.get_master_json(locale: "fr_FR")
    end
  end

  describe "import_master_json/1" do
    test "creates a POST to /v2/translations/master-json", %{bypass: bypass} do
      attrs = %{"locale" => "en_US", "masterJson" => %{"wf" => %{"hello" => "Hello"}}}

      Bypass.expect(bypass, "POST", "/v2/translations/master-json", fn conn ->
        assert read_json_body(conn) == attrs
        novu_response(conn, 200, %{success: true})
      end)

      assert {:ok, _} = Translations.import_master_json(attrs)
    end
  end

  describe "upload_master_json/1" do
    test "sends a multipart body with a `file` field from a tuple", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v2/translations/master-json/upload", fn conn ->
        assert [{"file", "en_US.json", ~s({"wf":{}})}] = read_multipart(conn)
        novu_response(conn, 200, %{success: true})
      end)

      assert {:ok, _} = Translations.upload_master_json({"en_US.json", ~s({"wf":{}})})
    end

    test "reads a file from a path", %{bypass: bypass} do
      path = Path.join(System.tmp_dir!(), "master_#{System.unique_integer([:positive])}")
      File.mkdir_p!(path)
      file = Path.join(path, "de_DE.json")
      File.write!(file, ~s({"a":1}))
      on_exit(fn -> File.rm_rf!(path) end)

      Bypass.expect(bypass, "POST", "/v2/translations/master-json/upload", fn conn ->
        assert [{"file", "de_DE.json", ~s({"a":1})}] = read_multipart(conn)
        novu_response(conn, 200, %{success: true})
      end)

      assert {:ok, _} = Translations.upload_master_json(file)
    end

    test "returns an error for an unreadable path" do
      assert {:error, {:file_error, "/nonexistent/en_US.json", :enoent}} =
               Translations.upload_master_json("/nonexistent/en_US.json")
    end
  end

  describe "upload_translation_files/3" do
    test "sends resourceId, resourceType and files fields", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/v2/translations/upload", fn conn ->
        parts = read_multipart(conn)

        assert {"resourceId", nil, "my-wf"} in parts
        assert {"resourceType", nil, "workflow"} in parts
        assert {"files", "en_US.json", ~s({"a":"b"})} in parts
        assert {"files", "es_ES.json", ~s({"a":"c"})} in parts
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} =
               Translations.upload_translation_files("workflow", "my-wf", [
                 {"en_US.json", ~s({"a":"b"})},
                 {"es_ES.json", ~s({"a":"c"})}
               ])
    end

    test "reads files from paths", %{bypass: bypass} do
      dir = Path.join(System.tmp_dir!(), "tr_#{System.unique_integer([:positive])}")
      File.mkdir_p!(dir)
      file = Path.join(dir, "fr_FR.json")
      File.write!(file, ~s({"x":"y"}))
      on_exit(fn -> File.rm_rf!(dir) end)

      Bypass.expect(bypass, "POST", "/v2/translations/upload", fn conn ->
        assert {"files", "fr_FR.json", ~s({"x":"y"})} in read_multipart(conn)
        novu_response(conn, 200, %{data: []})
      end)

      assert {:ok, _} = Translations.upload_translation_files("layout", "l", [file])
    end

    test "returns an error without a request when a file is unreadable" do
      assert {:error, {:file_error, "/nonexistent/en_US.json", :enoent}} =
               Translations.upload_translation_files("workflow", "wf", ["/nonexistent/en_US.json"])
    end
  end
end
