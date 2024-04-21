import vertex_leap, jsony, std/[unittest, options, os]


# gemini-1.0-pro-002
# gemini-1.0-pro-vision-001
# gemini-1.5-pro-preview-0409


suite "gemini pro":
  var vertexai: VertexAIAPI

  setup:

    let credentialPath = os.getEnv("GOOGLE_APPLICATION_CREDENTIALS", "")
    if credentialPath == "":
      let credStr = readFile("tests/service_account.json")
      let creds = fromJson(credStr, GCPCredentials)
      vertexai = newVertexAIAPI(credentials = option(creds))
    else:
      vertexai = newVertexAIAPI()
  teardown:
    vertexai.close()

  suite "1.0-pro-002":
    test "get":
      let prompt = "Please talk like a pirate. you are Longbeard the Llama."
      let resp = vertexai.geminiProGenerate("gemini-1.0-pro-002", prompt)
      echo resp
