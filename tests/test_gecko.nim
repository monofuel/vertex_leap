import vertex_leap, jsony, std/[unittest, options, os]

const
  Gecko = "textembedding-gecko@003"


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

  suite "gecko":
    test "get":
      let prompt = "Please talk like a pirate. you are Longbeard the Llama."
      let resp = vertexai.geckoTextEmbed(Gecko, prompt)
      echo resp.len
      var sum: float = 0
      for i in resp:
        sum += i
      echo sum