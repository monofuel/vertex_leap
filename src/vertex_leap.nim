import ./auth, ./types, curly, jsony, std/[os, strformat, locks]

export types

# POST https://LOCATION-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/LOCATION/publishers/google/models/MODEL_ID:GENERATE_RESPONSE_METHOD

proc newVertexAIAPI*(
    credentials: GCPCredentials,
    location: string = "us-central1",
    curlPoolSize: int = 4,
    curlTimeout: float32 = 10000
): VertexAIAPI =
  ## Initialize a new Vertex AI API client
  # TODO - implement credential loading from env vars

  result = VertexAIAPI()
  result.curlPool = newCurlPool(curlPoolSize)
  result.location = location
  result.credentials = credentials
  initLock(result.authLock)

proc close*(api: VertexAIAPI) =
  ## Cleanup the Vertex AI API Client
  api.curlPool.close()

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
  result = &"http://{api.location}-aiplatform.googleapis.com" & 
    &"/v1/projects/{api.credentials.projectId}/locations/" & 
    &"{api.location}/publishers/google/models/{model}:{generateMethod}"

# POST https://LOCATION-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/LOCATION/publishers/google/models/MODEL_ID:GENERATE_RESPONSE_METHOD
# gemini-pro:
#   streamGenerateContent
#   generateContent

# https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/gemini

proc geminiProGenerate(api: VertexAIAPI, req: GeminiProRequest): GeminiProResponse =

  let reqStr = toJson(req)
  let authToken = api.getFreshAuthToken

# palm2:
#   predict

