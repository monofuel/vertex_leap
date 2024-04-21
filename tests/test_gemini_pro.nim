import vertex_leap, jsony, std/[unittest, options, os]


# gemini-1.0-pro-002
# gemini-1.0-pro-vision-001
# gemini-1.5-pro-preview-0409

const
  Gemini_1_5_pro = "gemini-1.5-pro-preview-0409"
  Gemini_1_0_pro_002 = "gemini-1.0-pro-002"
  Gemini_1_0_pro_vision_001 = "gemini-1.0-pro-vision-001"

let testImageUrl = "gs://monofuel_llm_test/server_4u.jpg"

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
      let resp = vertexai.geminiProGenerate(Gemini_1_0_pro_002, prompt)
      echo resp
  suite "1.0-pro-vision-001":
    test "get":
      let prompt = "Please talk like a pirate. you are Longbeard the Llama."
      let resp = vertexai.geminiProGenerate(Gemini_1_0_pro_vision_001, prompt)
      echo resp
    test "image":
      let system = "Please talk like a pirate. you are Longbeard the Llama."
      let prompt = "Describe the image."
      let resp = vertexai.geminiProGenerate(Gemini_1_0_pro_vision_001, system & "\n" & prompt, image = testImageUrl)
      echo resp
  suite "1.5-pro":
    test "get":
      let prompt = "Please talk like a pirate. you are Longbeard the Llama."
      let resp = vertexai.geminiProGenerate(Gemini_1_5_pro, prompt)
      echo resp
    test "image":
      let system = "Please talk like a pirate. you are Longbeard the Llama."
      let prompt = "Describe the image."
      let resp = vertexai.geminiProGenerate(Gemini_1_5_pro, prompt, system = system, image = testImageUrl)
      echo resp