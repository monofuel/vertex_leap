import vertex_leap, jsony, std/[unittest, os]


# gemini-1.0-pro-002
# gemini-1.0-pro-vision-001
# gemini-1.5-pro-preview-0409


suite "gemini pro":
  var vertexai: VertexAIAPI

  setup:
    let credStr = readFile("tests/service_account.json")
    let creds = fromJson(credStr, GCPCredentials)
    vertexai = newVertexAIAPI(credentials = creds)
  teardown:
    vertexai.close()

  suite "1.5":
    test "get":
      echo "TODO"