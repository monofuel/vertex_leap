import vertex_leap, jsony, std/[unittest, options, os]

const
  ChatBison = "chat-bison@002"
  CodeChatBison = "codechat-bison@002"

let testImageUrl = "gs://monofuel_llm_test/server_4u.jpg"

suite "palm2":
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

  suite "chat-bison":
    test "get":
      let prompt = "Please talk like a pirate. you are Longbeard the Llama."
      let resp = vertexai.chatBisonChatGenerate(ChatBison, prompt)
      echo resp
  suite "codechat-bison":
    test "get":
      let prompt = "Please talk like a pirate. you are Longbeard the Llama."
      let resp = vertexai.chatBisonChatGenerate(CodeChatBison, prompt)
      echo resp
