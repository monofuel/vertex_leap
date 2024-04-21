import ./auth, ./types, curly, jsony, std/[os, strformat, options, locks]

proc newVertexAIAPI*(
    location: string = "us-central1",
    credentials: Option[GCPCredentials] = none(GCPCredentials),
    curlPoolSize: int = 4,
    curlTimeout: float32 = 10000
): VertexAIAPI =
  ## Initialize a new Vertex AI API client
  result = VertexAIAPI()

  if credentials.isNone:
    echo "DEBUG: loading credentials from GOOGLE_APPLICATION_CREDENTIALS"
    let credentialPath = os.getEnv("GOOGLE_APPLICATION_CREDENTIALS", "")
    if credentialPath == "":
      raise newException(CatchableError, "GOOGLE_APPLICATION_CREDENTIALS not set")
    let credStr = readFile(credentialPath)
    let credJson = fromJson(credStr, GCPCredentials)
    result.credentials = credJson
  else:
    echo &"DEBUG: using provided credentials"
    result.credentials = credentials.get

  result.curlPool = newCurlPool(curlPoolSize)
  result.location = location
  result.curlTimeout = curlTimeout
  initLock(result.authLock)

proc close*(api: VertexAIAPI) =
  ## Cleanup the Vertex AI API Client
  api.curlPool.close()

proc get*(api: VertexAIAPI, uri: string): Response =
  ## Make a GET request to the Vertex AI API
  var headers: curly.HttpHeaders
  headers["Content-Type"] = "application/json"
  headers["Authorization"] = "Bearer " & api.getFreshAuthToken()
  let resp = api.curlPool.get(uri, headers, api.curlTimeout)
  if resp.code != 200:
    raise newException(CatchableError, &"vertex call {uri} failed: {resp.code} {resp.body}")
  result = resp

proc post*(api: VertexAIAPI, uri: string, body: string): Response =
  ## Make a POST request to the Vertex AI API
  var headers: curly.HttpHeaders
  headers["Content-Type"] = "application/json"
  headers["Authorization"] = "Bearer " & api.getFreshAuthToken()
  let resp = api.curlPool.post(uri, headers, body,
      api.curlTimeout)
  if resp.code != 200:
    raise newException(CatchableError, &"vertex call {uri} failed: {resp.code} {resp.body}")
  result = resp


proc getGenerateUrl*(
  api: VertexAIAPI,
  model: string,
  generateMethod: string = "generateContent"
  ): string =
  ## Get the URL for the generate method
  ## palm2 models use "predict"
  ## gemini-pro models use "generateContent"
  ## streamGenerateContent is also valid but I'm not implementing it for now
  # most LLM work goes through this API, however the request / response format is often totally different
  result = &"https://{api.location}-aiplatform.googleapis.com" & 
    &"/v1/projects/{api.credentials.projectId}/locations/" & 
    &"{api.location}/publishers/google/models/{model}:{generateMethod}"


